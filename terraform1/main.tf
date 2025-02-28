- name: Setup Kubernetes Cluster
  hosts: kubernetes
  become: yes
  tasks:

    # Désactivation du swap (obligatoire pour Kubernetes)
    - name: Disable swap (Kubernetes requirement)
      command: swapoff -a
      ignore_errors: yes

    - name: Remove swap entry from /etc/fstab
      lineinfile:
        path: /etc/fstab
        regexp: '.*swap.*'
        state: absent

    # Mise à jour des paquets système
    - name: Update system packages
      apt:
        update_cache: yes
        cache_valid_time: 3600

    # Installation des paquets nécessaires
    - name: Install required packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present

    # Ajout de la clé GPG de Docker
    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    # Ajout du dépôt Docker
    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        filename: docker

    # Mise à jour du cache APT après l'ajout du dépôt Docker
    - name: Update apt cache after adding Docker repository
      apt:
        update_cache: yes

    # Installation de Docker
    - name: Install Docker
      apt:
        name: docker-ce
        state: present

    # Activation et démarrage du service Docker
    - name: Enable and start Docker service
      service:
        name: docker
        enabled: yes
        state: started

    # Ajout de l'utilisateur au groupe Docker
    - name: Add user to Docker group
      user:
        name: adminuser
        groups: docker
        append: yes

    # Ajout de la clé GPG de Kubernetes
    - name: Add Kubernetes GPG key
      get_url:
        url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
        dest: /etc/apt/trusted.gpg.d/kubernetes.asc

    # Ajout du dépôt Kubernetes
    - name: Add Kubernetes repository
      lineinfile:
        path: /etc/apt/sources.list.d/kubernetes.list
        line: "deb https://apt.kubernetes.io/ kubernetes-xenial main"
        create: yes

    # Mise à jour de la liste des paquets
    - name: Update package list
      apt:
        update_cache: yes

    # Installation des composants Kubernetes
    - name: Install Kubernetes components
      apt:
        name:
          - kubelet
          - kubeadm
          - kubectl
        state: present

    # Activation et démarrage du service kubelet
    - name: Enable kubelet service
      service:
        name: kubelet
        enabled: yes
        state: started

    # Configuration des paramètres sysctl pour le réseau Kubernetes
    - name: Configure sysctl settings for Kubernetes networking
      sysctl:
        name: net.bridge.bridge-nf-call-iptables
        value: '1'
        state: present
        reload: yes

    # Configuration des paramètres sysctl pour l'IP forwarding
    - name: Configure sysctl settings for IP forwarding
      sysctl:
        name: net.ipv4.ip_forward
        value: '1'
        state: present
        reload: yes

    # Initialisation du cluster Kubernetes (uniquement sur le master)
    - name: Initialize Kubernetes master
      command: kubeadm init --pod-network-cidr=10.244.0.0/16
      when: inventory_hostname == 'resismart-master-vm'

    # Copier le fichier kubeconfig pour l'utilisateur admin (uniquement sur le master)
    - name: Copy kubeconfig for kubectl usage
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/adminuser/.kube/config
        owner: adminuser
        group: adminuser
        mode: 0600
      when: inventory_hostname == 'resismart-master-vm'

    # Installation d'un réseau CNI (par exemple, Calico)
    - name: Install Calico network plugin
      command: kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
      when: inventory_hostname == 'resismart-master-vm'

    # Vérification de l'état de kubelet
    - name: Ensure kubelet is running
      service:
        name: kubelet
        state: started

    # Reboot de la machine pour appliquer les changements (sur tous les nœuds)
    - name: Reboot the machine
      reboot:
        msg: "Rebooting to apply system changes for Kubernetes"
        pre_reboot_delay: 10
        post_reboot_delay: 30
        reboot_timeout: 600
        test_command: whoami
