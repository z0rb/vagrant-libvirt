# frozen_string_literal: true

require 'digest/md5'
require 'vagrant/util/retryable'

module VagrantPlugins
  module ProviderLibvirt
    module Cap
      class MountVirtioFS
        extend Vagrant::Util::Retryable

        def self.mount_virtiofs_shared_folder(machine, folders)
          folders.each do |_name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath]
            )

            # Do the actual creating and mounting
            machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

            # Mount
            mount_tag = Digest::MD5.new.update(opts[:hostpath]).to_s[0, 31]

            mount_opts = "-o #{opts[:mount_opts]}" if opts[:mount_opts]

            mount_command = "mount -t virtiofs #{mount_opts} '#{mount_tag}' #{expanded_guest_path}"
            retryable(on: Vagrant::Errors::LinuxMountFailed,
                      tries: 5,
                      sleep: 3) do
              machine.communicate.sudo(mount_command,
                                       error_class: Vagrant::Errors::LinuxMountFailed)
            end
          end
        end
      end

      class MountVirtioFSWin
        extend Vagrant::Util::Retryable

        def self.mount_virtiofs_shared_folder(machine, folders)
          # Do nothing
        end
      end
    end
  end
end
