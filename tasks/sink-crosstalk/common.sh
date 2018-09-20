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
################################################################################
function login_to_cluster_as_admin {
    eval "$GET_CREDENTIALS_HOOK"
}

function apply_syslog_receiver {
    local namespace=${1?}
    echo "
---
apiVersion: v1
kind: Pod
metadata:
  name: syslog-receiver-$namespace
  namespace: default
  labels:
    app: syslog-receiver-$namespace
spec:
  containers:
  - name: syslog-receiver
    image: oratos/syslog-receiver:latest
    imagePullPolicy: Always
    env:
    - name: SYSLOG_PORT
      value: \"8080\"
    - name: METRICS_PORT
      value: \"6061\"
    ports:
    - name: syslog
      containerPort: 8080
    - name: metrics
      containerPort: 6061
---
apiVersion: v1
kind: Service
metadata:
  name: syslog-receiver-$namespace
  namespace: default
spec:
  selector:
    app: syslog-receiver-$namespace
  ports:
  - protocol: TCP
    port: 8080
" | kubectl apply --filename -
}

function apply_emitter {
    local namespace=${1?}
    local count=${2?}
    echo "
apiVersion: batch/v1
kind: Job
metadata:
  name: emitter
  namespace: $namespace
spec:
  template:
    spec:
      containers:
      - name: syslog-receiver
        image: ubuntu:latest
        command:
        - bash
        - -c
        - |
          for i in {1..$count}; do
            echo \"log \$i line for $namespace\"
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

function apply_cluster_sink {
    echo "
apiVersion: apps.pivotal.io/v1beta1
kind: ClusterSink
metadata:
  name: crosstalk-cluster-sink
spec:
  type: syslog
  host: syslog-receiver-cluster.default.svc.cluster.local
  port: 8080
" | kubectl apply --filename -
}

function apply_namespace_sink {
    local namespace=${1?}

    echo "
apiVersion: apps.pivotal.io/v1beta1
kind: Sink
metadata:
  name: crosstalk-sink
  namespace: $namespace
spec:
  type: syslog
  host: syslog-receiver-$namespace.default.svc.cluster.local
  port: 8080
" | kubectl apply --filename -
}
