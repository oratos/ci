#!/bin/bash
function assert_success {
    if [ "$1" -ne 0 ]; then
        echo Expected apply to succeed
        exit 1
    fi
}

function assert_fail {
    if [ "$1" -eq 0 ]; then
        echo Expected apply to fail
        exit 1
    fi
}

function check_result_cnt {
    local expected=${1?}
    local result=${2?}
    local msg=${3?}

    if [ "$result" = "null" ]; then
       result="0"
    fi

    if [ "$result" != "$expected" ]; then
        echo "$msg, but was $result"
        exit 1
    fi
}

function print_section_msg {
    local msg=${1?}
    echo
    echo "========================="
    echo "= $msg ="
    echo "========================="
    echo
}

function ensure_variable_isset {
    local var=${1?}
    local message=${2:-"parameter name should be given"}
    if [ -z "$var" ]; then
        echo "Error: Certain variable($message) is not set"
        exit 1
    fi
}

function verify_pod_running {
    local podName=${1?}
    local namespace=${2:-"pks-system"}
    local n=0
    local maxN=5

    until [ "$n" -ge "$maxN" ]; do
        echo -n .
        status="$(
            kubectl get pod \
                "$podName" \
                --output=json \
                --namespace="$namespace" \
                | jq --join-output .status.phase
        )"
        if [ "$status" = "Running" ]; then
            return 0
        fi
        sleep 10
        n=$((n+1))
    done
    return 1
}

function verify_deployment_running {
    local label=${1?}
    local namespace=${2:-"pks-system"}
    local n=0
    local maxN=5

    echo "Verify deployment $label is running"
    until [ "$n" -ge "$maxN" ]; do
        echo -n .
        status="$(
            kubectl get pods \
                --selector="$label" \
                --output=json \
                --namespace="$namespace" \
                | jq --join-output .items[].status.phase
        )"
        if [ "$status" = "Running" ]; then
            return 0
        fi
        sleep 10
        n=$((n+1))
    done
    return 1
}

function verify_daemonset_running {
    local label=${1?}
    local namespace=${2:-"pks-system"}
    local n=0
    local maxN=5

    nodes="$(kubectl get nodes --output json | jq '.items | length')"
    echo "Verify daemonset $label is running"
    until [ "$n" -ge "$maxN" ]; do
        echo -n .

        # Dont quit the script if fails to grep
        set +e
        ds_running_count="$(
            kubectl get pods \
                --selector="$label" \
                --namespace="$namespace" \
                --output=json \
                | jq '.items[].status.phase == "Running"' \
                | grep -c true
        )"
        set -e

        if [ "$ds_running_count" -eq "$nodes" ]; then
           return 0
        fi
        sleep 10
        n=$((n+1))
    done
    return 1
}

function retry_command {
    local command=${1?}
    local timeout_seconds=${2?}
    local sleep_duration=${3:-3}
    local report_stdout=${4:-false}
    local stdout
    local n=0

    until [ "$n" -ge "$timeout_seconds" ]; do
        if stdout="$(eval "$command" 2>/dev/null)"; then
            if [ "$report_stdout" = "true" ]; then
                echo "$stdout"
            fi
            return
        fi
        n=$((n+sleep_duration))

        echo "Sleep $sleep_duration seconds: $command" >&2
        sleep "$sleep_duration"
    done

    echo "After waiting for $timeout_seconds seconds, it still fails" >&2
    exit 1
}

################################################################################
function login_to_cluster_as_admin {
    local ret
    [ -n "${DEBUG:-}" ] && set +x
    eval "$GET_CREDENTIALS_HOOK"
    ret=$?
    [ -n "${DEBUG:-}" ] && set -x
    return "$ret"
}

function apply_crosstalk_receiver {
    local drain_namespace=${1?}
    local message=${2:-"crosstalk-test"}
    echo "
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: crosstalk-receiver
spec:
  volumes:
  - secret
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: crosstalk-receiver
  namespace: default
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: crosstalk-receiver
  namespace: default
rules:
- apiGroups:
  - policy
  resources:
  - podsecuritypolicies
  verbs:
  - use
  resourceNames:
  - crosstalk-receiver
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: crosstalk-receiver
  namespace: default
subjects:
- kind: ServiceAccount
  name: crosstalk-receiver
  namespace: default
roleRef:
  kind: Role
  name: crosstalk-receiver
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: crosstalk-receiver-$drain_namespace
  namespace: default
  labels:
    app: crosstalk-receiver-$drain_namespace
spec:
  serviceAccountName: crosstalk-receiver
  containers:
  - name: crosstalk-receiver
    image: oratos/crosstalk-receiver:v0.5
    imagePullPolicy: Always
    env:
    - name: SYSLOG_PORT
      value: \"8080\"
    - name: METRICS_PORT
      value: \"6061\"
    - name: MESSAGE
      value: $message
    ports:
    - name: syslog
      containerPort: 8080
    - name: metrics
      containerPort: 6061
---
apiVersion: v1
kind: Service
metadata:
  name: crosstalk-receiver-$drain_namespace
  namespace: default
spec:
  selector:
    app: crosstalk-receiver-$drain_namespace
  ports:
  - protocol: TCP
    port: 8080
" | kubectl apply --filename -
}

function apply_emitter {
    local namespace=${1?}
    local count=${2?}
    echo "
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: emitter
spec:
  volumes:
  - secret
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emitter
  namespace: $namespace
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: emitter
  namespace: $namespace
rules:
- apiGroups:
  - policy
  resources:
  - podsecuritypolicies
  verbs:
  - use
  resourceNames:
  - emitter
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: emitter
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: emitter
  namespace: $namespace
roleRef:
  kind: Role
  name: emitter
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: Job
metadata:
  name: emitter
  namespace: $namespace
spec:
  template:
    spec:
      serviceAccountName: emitter
      containers:
      - name: crosstalk-receiver
        image: ubuntu:latest
        command:
        - bash
        - -c
        - |
          for i in {1..$count}; do
            echo \"crosstalk-test: log \$i line for $namespace\"
          done
        imagePullPolicy: Always
      restartPolicy: Never
" | kubectl apply --filename -
}

function apply_roles {
    echo "
apiVersion: v1
kind: Namespace
metadata:
  name: crosstalk-ns-a
---
apiVersion: v1
kind: Namespace
metadata:
  name: crosstalk-ns-b
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: crosstalk-ns-a
  name: crosstalk-ns-a-user
rules:
- apiGroups:
  - \"\"
  - apps
  - extensions
  - batch
  - autoscaling
  - apps.pivotal.io
  resources:
  - \"*\"
  verbs:
  - \"*\"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: crosstalk-ns-b
  name: crosstalk-ns-b-user
rules:
- apiGroups:
  - \"\"
  - apps
  - extensions
  - batch
  - autoscaling
  - apps.pivotal.io
  resources:
  - \"*\"
  verbs:
  - \"*\"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: crosstalk-ns-a-user-binding
  namespace: crosstalk-ns-a
subjects:
- kind: User
  name: naomi-a
  apiGroup: \"\"
roleRef:
  kind: Role
  name: crosstalk-ns-a-user
  apiGroup: \"\"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: crosstalk-ns-b-user-binding
  namespace: crosstalk-ns-b
subjects:
- kind: User
  name: naomi-b
  apiGroup: \"\"
roleRef:
  kind: Role
  name: crosstalk-ns-b-user
  apiGroup: \"\"
" | kubectl apply --filename -
}

function apply_namespace_sink {
    local namespace=${1?}

    echo "
apiVersion: apps.pivotal.io/v1beta1
kind: LogSink
metadata:
  name: crosstalk-sink
  namespace: $namespace
spec:
  type: syslog
  host: crosstalk-receiver-$namespace.default.svc.cluster.local
  port: 8080
" | kubectl apply --filename -
}

function assert_gt {
    local a=${1?}
    local b=${2?}

    if [ -z "$a" ] || [ "$a" = "null" ]; then
       a=0
    fi
    if [ -z "$b" ] || [ "$b" = "null" ]; then
       b=0
    fi

    if ! [ "$a" -gt "$b" ]; then
        echo "We did not receive enough logs.  $a !> $b"
        exit 1
    fi
}

function assert_log_count_gt {
    local starting_count=${1?}
    local namespace=${2?}
    local ip=${3?}
    local metrics
    local result

    metrics="$(curl --silent "http://$ip:6061/metrics")"
    result="$(
        echo "$metrics" \
            | jq '.namespaced["'"$namespace"'"]' --join-output
    )"
    assert_gt "$result" "$starting_count"
    echo "$metrics"
}

function assert_cmd_fail {
    local command=${1?}

    if eval "$command"; then
        echo "expected command to fail"
        echo "$command"
        exit 1
    fi
}
