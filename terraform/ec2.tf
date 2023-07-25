data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_network_interface" "interface" {
  subnet_id       = "subnet-04738c8b8adf0d1f6"
  security_groups = [aws_security_group.allow_tls.id]
}

resource "aws_instance" "ec2" {
  depends_on           = [aws_network_interface.interface]
  ami                  = data.aws_ami.amazon-linux-2.id
  instance_type        = "t2.medium"
  user_data            = <<EOF
       #!/bin/bash

       #####JENKINS#######
       yum update -y
       wget -O /etc/yum.repos.d/jenkins.repo \
           https://pkg.jenkins.io/redhat-stable/jenkins.repo
       rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
       yum upgrade -y
       amazon-linux-extras install java-openjdk11 -y
       yum install jenkins git -y

       #######DOCKER############
       yum install -y docker
       systemctl start docker
       usermod -aG docker jenkins
       systemctl start jenkins
       
       ####KUBECTLandHELM######
       curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl
       install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
       curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2
       
       ######KIND########
       [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
       chmod +x ./kind
       sudo mv ./kind /usr/local/bin/kind
       aws s3 cp s3://pragmatic-gskorchev-final/kind.yaml /var/lib/jenkins/
       kind create cluster --config=/var/lib/jenkins/kind.yaml
       mkdir -p /var/lib/jenkins/.kube/
       kind get kubeconfig --name=kind > /var/lib/jenkins/.kube/config 
       chown -R jenkins: /var/lib/jenkins/.kube/
EOF
  iam_instance_profile = aws_iam_instance_profile.profile.name
  network_interface {
    network_interface_id = aws_network_interface.interface.id
    device_index         = 0
  }
  tags = {
    Name = "Jenkins"
  }
}
