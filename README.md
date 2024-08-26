# Terraform

Terraform is a free and open-source tool that enables the provisioning and management of infrastructure across various cloud platforms, including on-premises environments. It supports a wide range of providers, offering extensive compatibility with different platforms. Terraform uses the HashiCorp Configuration Language (HCL) to define infrastructure as code. The tool operates through three primary stages: Init, Plan, and Apply, which handle the transition from the current state to the desired configuration. Each infrastructure component managed by Terraform is referred to as a resource.

## Installation

https://developer.hashicorp.com/terraform/install

### Windows

```bash
choco install terraform
```

### macOS

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Linux

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Commands

* `terraform init`: When running `terraform init`, *Terraform* downloads and installs all plugins required for the providers used in the configuration. There are official providers maintained by HashiCorp (AWS, Azure, GCP, ...), partners providers certified by HashiCorp (DigitalOcean, Heroku, ...) and community providers. Plugins can be found by `registry/organization/plugin` like `registry.terraform.io/hashicorp/local
* `terraform plan`: prints the execution plan.
* `terraform apply`: applies the execution plan and deletes and creates resources.
* `terraform show`: prints the current infrastructure state. Can also combined with `-json` flag.
* `terraform destroy`: deletes all terraform managed resources.
* `terraform validate`: checks the files and shows errors.
* `terraform fmt`: formats all `.tf` files.
* `terraform providers`: lists all used providers.
* `terraform output`: prints all output variables.
* `terraform refresh`: synchronizes the state-file with the real world. This is also called by plan and apply.
* `terraform graph`: prints a dependency graph. Together with `graphviz` can plot a graph. First install graphviz using `apt install graphviz` and then run `terraform graph | dot -Tsvg > graph.svg`.


## State

Terraform tracks the state in its `terraform.tfstate` JSON state file. Planning an execution is always done based on this file.

The file is created with the first run of `terraform apply`. At that moment, the state is also refreshed from the real world. For performance reasons, this can be suppressed by running `terraform plan --refresh=false`.

When working as a team, the state should be stored in a remote data store so that it is shared. The state file also contains sensitive information and should be kept secret. That is why it should not be stored in Git but in secure file storage instead, such as AWS S3 or Google Cloud Storage.

Another reason for storing the state file in a shared location is to lock the file if an apply is in progress. This prevents two users from running apply concurrently.

Terraform follows the principle of *Immutable Infrastructure*. This means that updating a resource to a new version will delete and re-create it rather than modify it. This prevents configuration drift.

### Taint

When a resource provisioning fails, the resource is marked as *tainted*. It will be re-created with the next *apply*. A resource can also be "untainted" by running `terraform untaint <resource.name>`.


### Remote backend with AWS

The remote backend is used for storing the state file and support state locking.

First, prepare AWS by creating a S3 bucket and DynamoDB:

```
provider "aws" {
   region = "eu-central-1"
}

resource "aws_dynamodb_table" "mroc-dynamodb-terraform-lock" {
   name = "mroc-dynamodb-terraform-lock"
   hash_key = "LockID"
   billing_mode = "PAY_PER_REQUEST"

   attribute {
      name = "LockID"
      type = "S"
   }
}

resource "aws_s3_bucket" "mroc-s3-terraform-lock" {
  bucket = "mroc-s3-terraform-lock"
}
```

Then in the actual project, configure it to store the state file inside S3:

```
terraform {
  backend "s3" {
    bucket = "mroc-s3-terraform-lock"
    key = "folder/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "mroc-dynamodb-terraform-lock"
  }
}
```

To verify the file is stored in S3, the following commands can be used: `aws s3api list-objects --bucket mroc-s3-terraform-lock`


### Show state

To see what resources were created we can use `terraform state list`. To show details for a specific resource, use `terraform state show <resource>`.

To rename a resource, we can use `terraform state mv <type.name1> <type.name2>`.

With `terraform state pull`, the remote state can be viewed.

With `terraform state rm <resource>`, a resource can be removed from terraform management.


### Debug

To get more information from Terraform we can set its logging level using `export TF_LOG=<log_level>` with `log_level` being one of `INFO`, `WARNING`, `ERROR`, `DEBUG` or `TRACE`.

To collect Terraform logging in files we can also specify a log file location like` export TF_LOG_PATH=/tmp/terraform.log`.

### Import

To import existing resource into Terraform that are not yet under control we can use `terraform import <resource_type>.<resource_name> <attribute>`. This will print a placeholder for the `main.tf` file that needs to be pasted. After running the command again, we can copy the missing attributes from the state file.

### Workspaces

Workspaces allow to use the same files for different instances. The state is then stored inside of a state directory per workspace.

- `terraform workspace new <project-name>` creates a workspace.
- `terraform workspace list` will list all workspaces.
- `terraform workspace select <project-name>` switches a workspace.


```tf
variable "region" {
  type = map
  default = {
    "us-payroll" = "us-east-1"
    "uk-payroll" = "eu-west-2"
  }
}

module "payroll_app" {
  source = "/root/terraform-projects/modules/payroll-app"
  app_region = lookup(var.region, terraform.workspace)
  ami        = lookup(var.ami, terraform.workspace)
}
```


## HCL Declarative Language

```hcl
<block> <parameters> {
    key1 = value1
    key2 = value2
}
```

```hcl
resource "local_file" "pet" { 
    filename = "/root/pets.txt"
    content = "We love pets!"
}
```

```
resource: block name
"local_file": "local"=provider, "file"=resource
"pet": resource name
{}: key/value pairs arguments
```

https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file

## Examples

```
resource "local_file" "pet" { 
    filename = "/root/pets.txt"
    content = "We love pets!"
}
```

```
resource "random_pet" "pet-name" {
    prefix = "Mrs"
    separator = "."
    length = "2"
}
```

```
resource "tls_private_key" "pvtkey" {
  algorithm = "RSA"
  rsa_bits = 4096  
}

resource "local_file" "key_details" {
    filename = "/root/key.txt"
    content = tls_private_key.pvtkey.private_key_pem
}
```

## Variables

First create a variable file `variables.tf`:

```tf
variable "filename" {
    default = "/root/pets.txt"
    type = string
    description = "This variable is a filename"
}

variable "content" {
    default = "Hello world!"
    type = string
    description = "This variable is for file content"
}
```

Then in `main.tf`, use with prefix `var.`:

```tf
resource "local_file" "pet" {
    filename = var.filename
    content = var.content
}
```


### Variable types

#### String

```tf
variable "name" {
    type = string
    default = "text"
    description = "This is a string"
}
```

#### Number

```tf
variable "count" {
    type = number
    default = 1
    description = "This is a number"
}
```

#### Boolean

```tf
variable "flag" {
    type = bool
    default = true
    description = "This is a boolean"
}
```

#### List

```tf
variable "prefix" {
    type = list(string)
    default = ["Mr", "Mrs"]
}
```

Elements can be accessed like `var.prefix[1]`. All elements in a list are of same type.

#### Map

```tf
variable "content" {
    type = map(string)
    default = {
        "key1" = "value1"
        "key2" = "value2"
    }
}
```

Elements can be accessed like `var.content["key1"]`.

#### Set

```tf
variable "bucket" {
    type = list(number)
    default = [1, 10, 100]
}
```

Elements can be accessed like `var.bucket[1]`.

#### Objects

```tf
variable "cat" {
    type = object({
        name = string
        color = string
        age = number
    })
    default = {
        name = "Bronko"
        color = "Brown"
        age = 12
    }
}
```

#### Tuples

```tf
variable "class" {
    type = tuple([string, number, bool])
    default = ["Hi", 10, true]
}
```

Tuples are similar to lists, however elements can have different types.


### Specify variable values

#### Interactive mode

When a variables is left empty, `terraform apply` will  switch to interactive mode and ask for a value for each variable.


#### Command line argument

Variables can be passed to `terraform apply` like this:

```bash
terraform apply -var "filename=/root/pets.txt" -var "content=Hello Earth!"
```


#### Environment variable

Alternatively, variables can also be set via *environment variables* when prefixed with `TF_VAR_`:

```bash
export TF_VAR_filename="/root/pets.txt"
export TF_VAR_content="Hello moon!"
terraform apply
```


#### Variable definition files

Add a file named `terraform.tfvars`:

```
filename = "/root/pets.txt"
content = "Hello jupiter!"
```

Then pass the file like this:

```bash
terraform apply -var-file terraform.tfvars
```

When a variable file is named `*.auto.tfvars`, it is automatically loaded.


https://developer.hashicorp.com/terraform/language/expressions/types


### Output variables

Using `terraform output` we can print all output variables. In `main.tf`:

```
output "pet-name" {
    value = random_pet.my-pet.id
    description "Record of generated ID"
}
```


## Reference expressions

A resource can reference another resource like this:

```
resource "local_file" "pet" {
    filename = "/root/pet.txt"
    content = "Name is ${random_pet.my-pet.id}"
}

resource "random_pet" "my-pet" {
    prefix = "My"
    separator = "."
    length = 3
}
```


### Implicit dependency

In this case, the order is implicit and Terraform creates the resources in the order they depend on each other:

```
resource "local_file" "time" {
  filename = "/root/time.txt"
  content = "Stamp ${time_static.time_update.id}"
}

resource "time_static" "time_update" {
}
```


### Explicit dependency

To specify the order in which resources are created we can use the `depends_on` key:

```
resource "time_static" "time_update_1" {
  depends_on = [
    time_static.time_update_0
  ]
}

resource "time_static" "time_update_0" {
}
```

## Lifecycle rules

To prevent a resource to vanish during an update, the `lifecycle` can be set to `create_before_destroy`. This will ensure there will always be a resource during an update:

```
resource "time_static" "time_update" {
  lifecycle {
    create_before_destroy = true
  }
}
```

We can also prevent the deletion of a resource using `prevent_destroy` during `terraform apply`. Note that this will not prevent deletion when using `terraform destroy`:

```
resource "time_static" "time_update" {
  lifecycle {
    prevent_destroy = true
  }
}
```

To prevent the re-creation because of a change of specific properties we can use `ignore_changes` like this:

```
resource "time_static" "time_update" {
  tags {
    Name = "Project-A"
  }
  lifecycle {
    ignore_changes = [
        tags
    ]
  }
}
```

This can also be set to `all` like this:

```
resource "time_static" "time_update" {
  tags {
    Name = "Project-A"
  }
  lifecycle {
    ignore_changes = all
  }
}
```


## Datasources

Datasources allow Terraform to read and use values from outside its control, e.g. reading a configuration file. They are also called Data Resources.

```
output "os-version" {
  value = data.local_file.os.content
}
data "local_file" "os" {
  filename = "/etc/os-release"
}
```


## Meta-arguments

### Count

To create multiple instances of a resource we can use a meta-argument `count` and `count.index` like this:

```
resource "local_file" "animal" {
  filename = "/root/animal_${count.index}.txt"
  content = "I am animal ${count.index}"
  count = 3
}
```

The count can also be set to the length of variable array by using `length(var.names)`. Note: When deleting elements from a list it might happen that all elements in the list are replaced.

## For-each

```
variable "filenames" {
  type = set(string)
  default = [
    "/root/cat.txt",
    "/root/dog.txt",
    "/root/cow.txt"
  ]
}

resource "local_file" "pets" {
  filename = each.value
  content = each.value
  for_each = var.filenames
}
```

## Modules

Every directory with `.tf` files is regarded as a *local module*. To import another module, use the following block, including specifying variables:

```tf
module "module-name" {
  source = "../my-module"
  variable1 = "Hi"
}
```

Public modules can be found in the registry https://registry.terraform.io/browse/modules. Such a module can be imported like this:

```tf
module "iam_iam-user" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
  version                       = "5.28.0"
  name                          = "Max"
  create_iam_access_key         = false
  create_iam_user_login_profile = false
}
```

## Functions

Teraform supports a vide variety of function like:

- `length`: `length([1, 2, 3])`
- `index`: `index([1, 2, 3], 2)`
- `element`: `element([1, 2, 3], 1)`
- `contains`: `contains([1, 2, 3], 1)`
- `file`: `file("policy.json")`
- `foreach`: `foreach = var.regions`
- `max`: `max(-1, 2, 100)`, `max(var.options...)`
- `min`: `min(-1, 2, 100)`
- `ceil`: `ceil(10.4)`
- `floor`: `floor(10.4)`
- `split`: `split(",", "a,b,c")`
- `lower`: `lower("ABC")`
- `upper`: `upper("abc")`
- `substr`: `substr("abc", 1, 2)`
- `join`: `join(",", ["A", "B"])`
- `<`, `>`, `+`, `-`, `*`, `/`, `==`, `!=`, `&&`, `||`, `!`.
- `var.length < 8 ? 8 : var.length`.


Functions can be tested by running `terraform console`.


## AWS

The documentation for Terraform AWS provider can be found at https://registry.terraform.io/providers/hashicorp/aws/latest/docs.

Install the AWS command line interface following https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html.

```bash
choco install awscli
aws configure
aws help
```

After configuring, the credentials are stored in `~/.aws`. The syntax for the command follows `aws <command> <subcommand> [options and parameters]`.


### IAM

```bash
aws iam list-users
aws iam create-user 
aws iam create-user --user-name horst
aws iam get-user --user-name horst
aws attach-user-policy --user-name horst --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-group --group-name project-spark-developers
aws add-user-to-group --user-name host --group-name project-spark-developers
aws iam list-attached-group-policies --group-name project-spark-developers
aws iam list-attached-user-policies --user-name horst
aws iam attach-group-policy --group-name project-spark-developers --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

```tf
provider "aws" {
  region = "eu-central-1"
}

resource "aws_iam_user" "admin-user" {
  name = "lucy"
  tags = {
    Description = "Technical Team Leader"
  }
}

resource "aws_iam_policy" "admin-policy" {
  name = "AdminUsers"
  policy = file("admin-policy.json)
}
```

### S3

S3 can store files in buckets. Bucket name must be world-wide unique because it gets a DNS name. The content is accessible at `https://<bucket_name>.<region>.amazonaws.com/<path-name>/<file-name>`. Each object stored in a bucket has metadata. This includes the creation date and creator. Access is controlled via *Access Control Lists* and *Bucket Policies*.

```tf
resource "aws_s3_bucket" "finance" {
  bucket = "finance-acme-com"
}

resource "aws_s3_bucket_object" "pl2020" {
  content = "/root/finance/pl2020.docx"
  key = "finance-2020.docx"
  bucket = aws_s3_bucket.finance.id
}
```

### DynamoDB

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

```tf
resource "aws_dynamodb_table" "cars" {
  name = "cars"
  hash_key = "VIN"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "VIN"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "car-items" {
  table_name = aws_dynamodb_table.cars.name
  hash_key = aws_dynamodb_table.cars.hash_key
  item = <<EOF
  {
    "Manufacturer": {"S": "Toyota"},
    "Make": {"S": "Corolla"},
    "Year": {"N": "2004"},
    "VIN": {"S": "ABCD1234" },
  }
  EOF
}
```

### EC2

Elastic compute cloud runs Linux or Windows like any other VMs. There are pre-configured images called *Amazon Machine Images* (AMI) that are specific to regions. Instance types can be *General Purpose*, *Compute Optimized*, *Memory Optimized* and others. Storage is provided by *EBS Volume* which is *Elastic Block Storage*.

```
provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0e872aee57663ae2d"
  instance_type = "t2.micro"
  tags = {
    Name        = "webserver"
    Description = "An webserver on Ubuntu"
  }
  user_data              = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install nginx -y
              systemctl enable nginx
              systemctl start nginx
              EOF
  key_name               = aws_key_pair.web.id
  vpc_security_group_ids = [aws_security_group.ssh-access.id]
}

resource "aws_key_pair" "web" {
  public_key = file("./web.pub")
}

resource "aws_security_group" "ssh-access" {
  name        = "ssh-access"
  description = "Allows SSH access from internet"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "eip" {
  domain   = "vpc"
  instance = aws_instance.webserver.id
}

output "publicip" {
  value = aws_eip.eip.public_ip
}
```

`ssh -i ./key.pem ubuntu@123.123.123.123`