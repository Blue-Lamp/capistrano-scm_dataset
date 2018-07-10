dataset_plugin = self

namespace :dataset do
  desc 'Create dataset'
  task :create do
    run_locally do
      dataset_plugin.create
    end
  end

  desc 'Create release folder and upload files'
  task create_release: :'dataset:create' do
    on release_roles :all do
      dataset_plugin.release
    end
  end

  task :set_current_revision do
    run_locally do
      set :current_revision, dataset_plugin.fetch_revision
    end
  end
end
