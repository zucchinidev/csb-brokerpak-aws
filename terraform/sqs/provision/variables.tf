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

variable fifo { type = bool }
variable instance_name { type = string }
variable labels { type = map }
variable delay_seconds { type = number }
variable max_message_size { type = number }
variable message_retention_seconds { type = number }
variable receive_wait_time_seconds { type = number }
variable visibility_timeout_seconds { type = number }
variable redrive_policy { type = object(
  {
      deadLetterTargetArn = string
      maxReceiveCount = number
    }
  )}
