pipeline {
  agent any
  stages {
    stage("provisioning infrastructure") {
        environment {
            AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
            AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
            TF_VAR_github_token = credentials('git-token')
            TF_VAR_rds_username = credentials('db-username')
            TF_VAR_rds_password = credentials('db-password')
        }
        steps {
            script {
                    sh "terraform init"
                    sh "terraform apply -target=module.myapp-vpc -target=module.helm -target=module.RDS_DB -target=module.IRSA --auto-approve"
                    sh "terraform apply --auto-approve"
                    sh "terraform destroy --auto-approve"
            }
        }
    }
   }
}
