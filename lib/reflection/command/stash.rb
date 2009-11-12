require 'fileutils'

module Reflection
  module Command
    class Stash < Reflection::Command::Base

      def validate!
        validate.existence_of options.directory
      end

      def run!
        Reflection.log.info "Stashing '#{options.directory}'.."

        stash_directory = Directory::Stash.new(Reflection::Repository.new(options.repository))
        target_directory = Directory::Base.new(options.directory)

        if Repository.exists?(target_directory.path)
          Support.exit_with_error "The specified --directory is a repository. Reflection is afraid of breaking something, so it won't touch it. Pleace specify another one.."
        end

        if Repository.exists?(target_directory.parent.path)
          Support.exit_with_error "The parent of the specified --directory is a repository. Reflection is afraid of breaking something, so it won't touch it. Pleace specify another one.."
        end

        prepare_stash_repository(stash_directory)
        stash_directory_into_repository(stash_directory, target_directory)

        Reflection.log.info "Stash Command done."
      end

      def prepare_stash_repository(directory)
        Reflection.log.debug "Preparing stash repository.."

        if directory.exists?
          directory.validate_repository
        else
          directory.clone_repository
        end
      end

      def stash_directory_into_repository(stash_directory, target_directory)
        FileUtils.cp_r(stash_directory.git_index, target_directory.parent.path)
        
        repository = Repository.new_from_path(target_directory.parent.path)
        repository.commit_all_new_files(target_directory.name)
        repository.push

        FileUtils.rm_r(File.join(stash_directory.path, "/.git"))
        FileUtils.mv(target_directory.parent.git_index, stash_directory.path)
      end
      
    end
  end
end