# Helper:: WindowsHelper
#
# Author:: Jeremy Goodrum
# Email:: chef@exospheredata.com
#
# Version:: 0.1.0
# Date:: 2016-12-05
#
# This helper method is leveraged to mock a windows framework
# that allows chefspec testing to be performed on non-Windows
# platforms.
#
# Copyright:: 2016, Exosphere Data, LLC <chef@exospheredata.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Windows Helper Method
#
def mock_windows_system_framework
  allow_any_instance_of(Chef::Recipe)
    .to receive(:wmi_property_from_query)
    .and_return(true)
  allow_any_instance_of(Chef::DSL::RegistryHelper)
    .to receive(:registry_key_exists?)
    .and_return(false)
  allow_any_instance_of(Chef::DSL::RegistryHelper)
    .to receive(:registry_get_values)
    .and_return(nil)
  allow_any_instance_of(Chef::Win32::Registry)
    .to receive(:value_exists?)
    .and_return(false)
  # This is the best way that I could find to stub out the Windows::Helper
  # 'is_package_installed?'.
  allow_any_instance_of(Chef::Provider)
    .to receive(:is_package_installed?)
    .and_return(false)
end

def win_friendly_path(path)
  path.gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR || '\\') if path
end
