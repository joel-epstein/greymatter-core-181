// K8s manifests necessary for spire and openshift

package greymatter

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

openshift_privileged_scc: [
	rbacv1.#ClusterRole & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"rbac.authorization.kubernetes.io/autoupdate":                 "true"
			}
			name: "\(config.operator_namespace)-system:openshift:scc:gm-operator"
		}
		rules: [{
			apiGroups: ["security.openshift.io"]
			resourceNames: ["privileged"]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		}]
	},
	rbacv1.#ClusterRoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "\(config.operator_namespace)-system:openshift:scc:gm-operator"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:gm-operator"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "greymatter-operator"
			namespace: config.operator_namespace
		}]
	},
]

openshift_spire_scc: [
	{// SCC https://spiffe.io/docs/latest/deploying/spire_agent/#security-context-constraints
		allowHostDirVolumePlugin: true
		allowHostIPC:             true
		allowHostNetwork:         true
		allowHostPID:             true
		allowHostPorts:           true
		allowPrivilegeEscalation: true
		allowPrivilegedContainer: false
		allowedCapabilities:      null
		allowedUnsafeSysctls:     null
		apiVersion:               "security.openshift.io/v1"
		defaultAddCapabilities:   null
		fsGroup: type: "MustRunAs"
		groups: []
		kind: "SecurityContextConstraints"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"kubernetes.io/description":                                   "Customized policy for Spire to enable host level access."
				"release.openshift.io/create-only":                            "true"
			}
			name: "spire"
		}
		priority:               null
		readOnlyRootFilesystem: false
		requiredDropCapabilities: [ "KILL", "MKNOD", "SETUID", "SETGID"]
		runAsUser: type:          "RunAsAny"
		seLinuxContext: type:     "MustRunAs"
		supplementalGroups: type: "RunAsAny"
		users: []
		volumes: [
			"hostPath",
			"configMap",
			"downwardAPI",
			"emptyDir",
			"persistentVolumeClaim",
			"projected",
			"secret",
		]
	},
	rbacv1.#ClusterRole & {// spire SCC cluster role bound by everything that needs the spire SCC
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"rbac.authorization.kubernetes.io/autoupdate":                 "true"
			}
			name: "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		rules: [{
			apiGroups: ["security.openshift.io"]
			resourceNames: ["spire"]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		}]
	},
	rbacv1.#ClusterRoleBinding & {// The operator's own binding to the spire scc, so it can grant it to other things
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "\(config.operator_namespace)-system:openshift:scc:spire:gm-operator"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "greymatter-operator"
			namespace: config.operator_namespace
		}]
	},
]

// Bind Vector's ServiceAccount to the SCC - applied at mesh install time
openshift_vector_scc_bindings: [
	rbacv1.#ClusterRoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "\(config.operator_namespace)-vector-scc"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-vector-scc"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "greymatter-audit-agent"
			namespace: mesh.spec.install_namespace
		}]
	},
]

// SCC for permissioning Vector, applied at operator install time
openshift_vector_scc: [
	{
		apiVersion: "security.openshift.io/v1"
		kind:       "SecurityContextConstraints"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"kubernetes.io/description":                                   "Customized policy for Vector to enable hostPath volumes."
				"release.openshift.io/create-only":                            "true"
			}
			name: "vector-scc"
		}
		allowHostDirVolumePlugin: true
		allowHostIPC:             true
		allowHostNetwork:         false
		allowHostPID:             true
		allowHostPorts:           false
		allowPrivilegeEscalation: false
		allowPrivilegedContainer: false
		allowedCapabilities:      null
		allowedUnsafeSysctls:     null
		defaultAddCapabilities:   null
		fsGroup: type: "RunAsAny"
		groups: []
		priority:               null
		readOnlyRootFilesystem: true 
		requiredDropCapabilities: [ "KILL", "MKNOD", "SETUID", "SETGID"]
		runAsUser: type:          "RunAsAny"
		seLinuxContext: type:     "MustRunAs"
		supplementalGroups: type: "RunAsAny"
		users: []
		volumes: [
			"hostPath",
			"configMap",
			"downwardAPI",
			"emptyDir",
			"persistentVolumeClaim",
			"projected",
			"secret",
		]
	},
	rbacv1.#ClusterRole & {// vector-scc SCC cluster role bound by vector later
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"rbac.authorization.kubernetes.io/autoupdate":                 "true"
			}
			name: "\(config.operator_namespace)-vector-scc"
		}
		rules: [{
			apiGroups: ["security.openshift.io"]
			resourceNames: ["vector-scc"]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		}]
	},
	rbacv1.#ClusterRoleBinding & {// The operator's own binding to the vector-scc role, so it can grant it to other things
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "\(config.operator_namespace)-vector-scc:gm-operator"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-vector-scc"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "greymatter-operator"
			namespace: config.operator_namespace
		}]
	},
]

openshift_redis_scc: [
	{
		apiVersion: "security.openshift.io/v1"
		kind:       "SecurityContextConstraints"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"kubernetes.io/description":                                   "Customized policy for Redis to enable fsGroup volumes."
				"release.openshift.io/create-only":                            "true"
			}
			name: "\(config.operator_namespace)-redis-scc"
		}
		allowHostDirVolumePlugin: true
		allowHostIPC:             false
		allowHostNetwork:         false
		allowHostPID:             false
		allowHostPorts:           false
		allowPrivilegeEscalation: false
		allowPrivilegedContainer: false
		allowedCapabilities:      null
		allowedUnsafeSysctls:     null
		defaultAddCapabilities:   null
		fsGroup: type: "RunAsAny"
		groups: []
		priority:               null
		readOnlyRootFilesystem: false
		requiredDropCapabilities: [ "KILL", "MKNOD", "SETUID", "SETGID"]
		runAsUser: type:          "RunAsAny"
		seLinuxContext: type:     "MustRunAs"
		supplementalGroups: type: "RunAsAny"
		users: []
		volumes: [
			"hostPath",
			"configMap",
			"downwardAPI",
			"emptyDir",
			"persistentVolumeClaim",
			"projected",
			"secret",
		]
	},
	rbacv1.#ClusterRole & {// redis-scc SCC cluster role
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"rbac.authorization.kubernetes.io/autoupdate":                 "true"
			}
			name: "\(config.operator_namespace)-redis-scc"
		}
		rules: [{
			apiGroups: ["security.openshift.io"]
			resourceNames: ["redis-scc"]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		}]
	},
	rbacv1.#ClusterRoleBinding & {// Bind the SCC to the redis service account
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "redis-scc"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-redis-scc"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      defaults.redis_cluster_name
			namespace: mesh.spec.install_namespace
		}]
	},
]

openshift_prometheus_scc: [
	{
		apiVersion: "security.openshift.io/v1"
		kind:       "SecurityContextConstraints"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"kubernetes.io/description":                                   "Customized policy for Redis to enable fsGroup volumes."
				"release.openshift.io/create-only":                            "true"
			}
			name: "\(config.operator_namespace)-prometheus-scc"
		}
		allowHostDirVolumePlugin: false
		allowHostIPC:             false
		allowHostNetwork:         false
		allowHostPID:             false
		allowHostPorts:           false
		allowPrivilegeEscalation: false
		allowPrivilegedContainer: false
		allowedCapabilities:      null
		allowedUnsafeSysctls:     null
		defaultAddCapabilities:   null
		fsGroup: type: "RunAsAny"
		groups: []
		priority:               null
		readOnlyRootFilesystem: false
		requiredDropCapabilities: [ "KILL", "MKNOD", "SETUID", "SETGID"]
		runAsUser: type:          "RunAsAny"
		seLinuxContext: type:     "MustRunAs"
		supplementalGroups: type: "RunAsAny"
		users: []
		volumes: [
			"hostPath",
			"configMap",
			"downwardAPI",
			"emptyDir",
			"persistentVolumeClaim",
			"projected",
			"secret",
		]
	},
	rbacv1.#ClusterRole & {// redis-scc SCC cluster role
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			annotations: {
				"include.release.openshift.io/self-managed-high-availability": "true"
				"rbac.authorization.kubernetes.io/autoupdate":                 "true"
			}
			name: "\(config.operator_namespace)-prometheus-scc"
		}
		rules: [{
			apiGroups: ["security.openshift.io"]
			resourceNames: ["prometheus-scc"]
			resources: ["securitycontextconstraints"]
			verbs: ["use"]
		}]
	},
	rbacv1.#ClusterRoleBinding & {// Bind the SCC to the redis service account
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "\(config.operator_namespace)-prometheus-scc"
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "prometheus-scc"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "prometheus"
			namespace: mesh.spec.install_namespace
		}]
	},
]


openshift_spire: [
	// The actual ClusterRole these refer to is applied at install-time if openshift and spire are both on - see above
	rbacv1.#RoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "system:openshift:scc:spire:agent"
			namespace: defaults.spire.namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "agent"
			namespace: defaults.spire.namespace
		}]
	},
	// RoleBindings for greymatter services so they can access their agent.sock
	rbacv1.#RoleBinding & {// controlensemble
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "system:openshift:scc:spire:controlensemble"
			namespace: mesh.spec.install_namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "controlensemble"
			namespace: mesh.spec.install_namespace
		}]
	},
	rbacv1.#RoleBinding & {// prometheus
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "system:openshift:scc:spire:prometheus"
			namespace: mesh.spec.install_namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "prometheus"
			namespace: mesh.spec.install_namespace
		}]
	},
	rbacv1.#RoleBinding & {// default service account (used by sidecars without a service account)
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "system:openshift:scc:spire:default"
			namespace: mesh.spec.install_namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "\(config.operator_namespace)-system:openshift:scc:spire"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "default"
			namespace: mesh.spec.install_namespace
		}]
	},
]
