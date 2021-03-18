# Copyright 2020 Pivotal Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



resource "aws_sqs_queue" "queue" {
  name                       = "${trimsuffix(var.instance_name, ".fifo")}%{ if var.fifo }.fifo%{ endif }"
  fifo_queue                 = var.fifo
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  tags                       = var.labels
  redrive_policy             = var.redrive_policy != null ? jsonencode(var.redrive_policy) : ""
}
