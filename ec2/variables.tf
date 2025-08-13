    variable "ami_id" {
    type = string
    default = "ami-09c813fb71547fc4f" #optional
    description = "Ec2" #optional
    }

    variable "instance_type" {
        default = "t3.micro"
        type =  string
      
    }

    variable "security_group_ids" {
    type = list
    default = ["sg-0f8104ab660079896"] #replace with your SG ID.
    }

    variable "tags" {
        default = {
        projects = "Expense"
        module  = "db" 
        name = "db"
             
        } 
    }

    