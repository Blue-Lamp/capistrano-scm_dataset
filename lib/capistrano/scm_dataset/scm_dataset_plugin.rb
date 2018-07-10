require 'capistrano/scm/plugin'

module Capistrano
  module DatasetScm
    class ScmDatasetPlugin < Capistrano::SCM::Plugin
      def set_defaults
        set_if_empty :repo_url, '.'
        set_if_empty :repo_tree, '.'
        set_if_empty :files_dir, fetch(:tmp_dir)
        set_if_empty :files_exclude, []
      end

      def register_hooks
        after 'deploy:new_release_path', 'dataset:create_release'
        before 'deploy:set_current_revision', 'dataset:set_current_revision'
      end

      def define_tasks
        eval_rakefile File.expand_path('tasks/dataset.rake', __dir__)
      end

      def create
        excludes = fetch(:files_exclude).map { |file| "--exclude #{file}" }.join(' ')
        backend.execute(:mkdir, '-p', files_dir)
        backend.execute(
          :tar, '-C', dataset_root, '--exclude', files_dir, excludes, '-zcf',
          file_path, '.'
        )
      end

      def release
        backend.execute(:mkdir, '-p', release_path)
        backend.upload!(file_path, release_path)

        backend.within(release_path) do
          backend.execute :tar, '-zxf', File.basename(file_path)
          backend.execute :rm, '-f', File.basename(file_path)
        end
      end

      def fetch_revision
        backend.capture(:git, 'rev-parse', 'HEAD').strip
      end

      private

      def files_dir
        fetch(:files_dir)
      end

      def file_name
        "#{release_timestamp}.tar.gzip"
      end

      def file_path
        File.join(files_dir, file_name)
      end

      def dataset_root
        File.join(fetch(:repo_url), fetch(:repo_tree))
      end
    end
  end
end
