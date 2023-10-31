Login to the Openshift cluster cli using an account with cluster admin rights 

Generate a default project template 

    oc adm create-bootstrap-project-template -o yaml > template.yaml 
 
The template.yaml file looks similar to the example below 

    apiVersion: template.openshift.io/v1 
    kind: Template 
    metadata: 
     creationTimestamp: null 
       name: project-request 
    objects: 
    - apiVersion: project.openshift.io/v1 
      kind: Project 
      metadata: 
        annotations: 
          openshift.io/description: ${PROJECT_DESCRIPTION} 
          openshift.io/display-name: ${PROJECT_DISPLAYNAME} 
          openshift.io/requester: ${PROJECT_REQUESTING_USER} 
        creationTimestamp: null 
        name: ${PROJECT_NAME} 
      spec: {} 
      status: {} 
    - apiVersion: rbac.authorization.k8s.io/v1 
      kind: RoleBinding 
      metadata: 
        creationTimestamp: null 
        name: admin 
        namespace: ${PROJECT_NAME} 
      roleRef: 
        apiGroup: rbac.authorization.k8s.io 
        kind: ClusterRole 
        name: admin 
      subjects: 
      - apiGroup: rbac.authorization.k8s.io 
        kind: User 
        name: ${PROJECT_ADMIN_USER} 
    parameters: 
    - name: PROJECT_NAME 
    - name: PROJECT_DISPLAYNAME 
    - name: PROJECT_DESCRIPTION 
    - name: PROJECT_ADMIN_USER 
    - name: PROJECT_REQUESTING_USER 

Load the project template into Openshift
 
Load the project template into the openshift-config project 

    oc create -f template.yaml -n openshift-config 
 
Edit the project configuration resource to point to the new project template just added  
(its default name is project-request) 

    oc edit project.config.openshift.io/cluster 
 
    apiVersion: config.openshift.io/v1 
    kind: Project 
    metadata: 
      ... 
 
Add the following under the spec section 
 
    spec: 
      		projectRequestTemplate: 
       		 name: project-request 

Now that the default template is in effect, deny and allow policies can be added  

Once the LimitRange/ResourceQuota requirements have been identified and are ready to be added to the template, the default template needs editing to include them under the objects: array 

example 

    apiVersion: template.openshift.io/v1 
    kind: Template 
    metadata: 
      creationTimestamp: null 
      name: project-request 
      namespace: openshift-config 
    objects: 
    << add objects here >> 
 
Type the following command 

    oc edit template <project_template> -n openshift-config 
 
    apiVersion: template.openshift.io/v1 
    kind: Template 
    metadata: 
      creationTimestamp: null 
      name: project-request 
      namespace: openshift-config 
    objects: 
    - apiVersion: project.openshift.io/v1 
      kind: Project 
      metadata: 
        annotations: 
          openshift.io/description: ${PROJECT_DESCRIPTION} 
          openshift.io/display-name: ${PROJECT_DISPLAYNAME} 
          openshift.io/requester: ${PROJECT_REQUESTING_USER} 
        creationTimestamp: null 
        name: ${PROJECT_NAME} 
      spec: {} 
      status: {} 
    - apiVersion: rbac.authorization.k8s.io/v1 
      kind: RoleBinding 
      metadata: 
        creationTimestamp: null 
        name: admin 
        namespace: ${PROJECT_NAME} 
      roleRef: 
        apiGroup: rbac.authorization.k8s.io 
        kind: ClusterRole 
        name: admin 
      subjects: 
      - apiGroup: rbac.authorization.k8s.io 
       kind: User 
        name: ${PROJECT_ADMIN_USER} 

(The below section in red has been added to the default template)

    - apiVersion: v1 
      kind: LimitRange 
      metadata: 
        creationTimestamp: null 
        name: ${PROJECT_NAME}-limits 
      spec: 
        limits: 
        - type: Container 
          default: 
            cpu: 1000m 
            memory: 1Gi 
          defaultRequest: 
            cpu: 500m 
            memory: 500Mi 
    - apiVersion: v1 
      kind: ResourceQuota 
      metadata: 
        name: ${PROJECT_NAME}-quota 
      spec: 
        hard: 
          pods: "10" 
          requests.cpu: "4" 
          requests.memory: 8Gi 
          limits.cpu: "6" 
          limits.memory: 16Gi 
    - apiVersion: networking.k8s.io/v1 
      kind: NetworkPolicy 
      metadata: 
        name: deny-by-default 
      spec: 
        podSelector: {} 
        policyTypes: 
        - Ingress 
    - apiVersion: networking.k8s.io/v1 
      kind: NetworkPolicy 
      metadata: 
        name: allow-from-same-namespace 
      spec: 
        podSelector: {} 
        ingress: 
        - from: 
          - podSelector: {} 
    - apiVersion: networking.k8s.io/v1 
      kind: NetworkPolicy 
      metadata: 
        name: allow-from-openshift-ingress 
      spec: 
        ingress: 
        - from: 
          - namespaceSelector: 
              matchLabels: 
                network.openshift.io/policy-group: ingress 
        podSelector: {} 
        policyTypes: 
        - Ingress 
    - apiVersion: networking.k8s.io/v1 
      kind: NetworkPolicy 
      metadata: 
        name: allow-from-openshift-monitoring 
      spec: 
        ingress: 
        - from: 
          - namespaceSelector: 
              matchLabels: 
               network.openshift.io/policy-group: monitoring 
        podSelector: {} 
        policyTypes: 
        - Ingress 
        - apiVersion: networking.k8s.io/v1
          kind: NetworkPolicy
          metadata:
            name: allow-openshift-operators-redhat
      spec:
        ingress:
        - from:
          - podSelector: {}
        - from:
          - namespaceSelector:
              matchLabels:
                project: openshift-operators-redhat
    parameters: 
    - name: PROJECT_NAME 
    - name: PROJECT_DISPLAYNAME 
    - name: PROJECT_DESCRIPTION 
    - name: PROJECT_ADMIN_USER 
    - name: PROJECT_REQUESTING_USER 

Save the new configuration
