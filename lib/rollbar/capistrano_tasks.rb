require 'rollbar/deploy'

module Rollbar
  # Module containing the logic of Capistrano tasks for deploy tracking
  module CapistranoTasks
    class << self
      def deploy_started(capistrano, logger, dry_run)
        deploy_task(logger, :desc => 'Notifying Rollbar of deployment start') do
          result = report_deploy_started(capistrano, dry_run)

          debug_request_response(logger, result)

          capistrano.set(:rollbar_deploy_id, 123) if dry_run

          skip_in_dry_run(logger, dry_run) do
            if result[:success] && (deploy_id = result[:data] && result[:data][:deploy_id])
              capistrano.set :rollbar_deploy_id, deploy_id
            else
              logger.error 'Unable to report deploy to Rollbar' + (result[:message] ? ': ' + result[:message] : '')
            end
          end
        end
      end

      def deploy_succeeded(capistrano, logger, dry_run)
        deploy_update(capistrano, logger, dry_run, :desc => 'Setting deployment status to `succeeded` in Rollbar') do
          report_deploy_succeeded(capistrano, dry_run)
        end
        upload_sourcemaps(capistrano, logger, dry_run)
      end

      def upload_sourcemaps(capistrano, logger, dry_run)
        upload_sourcemaps_with_curl(capistrano, logger) if capistrano.fetch(:rollbar_sourcemaps_minified_url_base) && !dry_run
      end

      def deploy_failed(capistrano, logger, dry_run)
        deploy_update(capistrano, logger, dry_run, :desc => 'Setting deployment status to `failed` in Rollbar') do
          report_deploy_failed(capistrano, dry_run)
        end
      end

      private

      def deploy_task(logger, opts = {})
        capistrano_300_warning(logger)
        logger.info opts[:desc] if opts[:desc]
        yield

      rescue StandardError => e
        logger.error "Error reporting to Rollbar: #{e.inspect}"
      end

      def deploy_update(capistrano, logger, dry_run, opts = {})
        deploy_task(logger, opts) do
          depend_on_deploy_id(capistrano, logger) do
            result = yield

            debug_request_response(logger, result)

            skip_in_dry_run(logger, dry_run) do
              if result[:success]
                logger.info 'Updated deploy status in Rollbar'
              else
                logger.error 'Unable to update deploy status in Rollbar' + (result[:message] ? ': ' + result[:message] : '')
              end
            end
          end
        end
      end

      def capistrano_300_warning(logger)
        return unless ::Capistrano.const_defined?('VERSION') && ::Capistrano::VERSION =~ /^3\.0/

        logger.warn('You need to upgrade capistrano to >= 3.1 version in order'\
          'to correctly report deploys to Rollbar. (On 3.0, the reported revision'\
          'will be incorrect.)')
      end

      def report_deploy_started(capistrano, dry_run)
        ::Rollbar::Deploy.report(
          {
            :rollbar_username => capistrano.fetch(:rollbar_user),
            :local_username => capistrano.fetch(:rollbar_user),
            :comment => capistrano.fetch(:rollbar_comment),
            :status => :started,
            :proxy => :ENV,
            :dry_run => dry_run
          },
          capistrano.fetch(:rollbar_token),
          capistrano.fetch(:rollbar_env),
          capistrano.fetch(:rollbar_revision)
        )
      end

      def report_deploy_succeeded(capistrano, dry_run)
        ::Rollbar::Deploy.update(
          {
            :comment => capistrano.fetch(:rollbar_comment),
            :proxy => :ENV,
            :dry_run => dry_run
          },
          capistrano.fetch(:rollbar_token),
          capistrano.fetch(:rollbar_deploy_id),
          :succeeded
        )
      end

      def report_deploy_failed(capistrano, dry_run)
        ::Rollbar::Deploy.update(
          {
            :comment => capistrano.fetch(:rollbar_comment),
            :proxy => :ENV,
            :dry_run => dry_run
          },
          capistrano.fetch(:rollbar_token),
          capistrano.fetch(:rollbar_deploy_id),
          :failed
        )
      end

      def depend_on_deploy_id(capistrano, logger)
        if capistrano.fetch(:rollbar_deploy_id)
          yield
        else
          logger.error 'Failed to update the deploy in Rollbar. No deploy id available.'
        end
      end

      def skip_in_dry_run(logger, dry_run)
        if dry_run
          logger.info 'Skipping sending HTTP requests to Rollbar in dry run.'
        else
          yield
        end
      end

      def debug_request_response(logger, result)
        # NOTE: in Capistrano debug messages go to log/capistrano.log but not to stdout even if log_level == :debug
        logger.debug result[:request_info]
        logger.debug result[:response_info] if result[:response_info]
      end

      def upload_sourcemaps_with_curl(capistrano, logger)
        url_base = capistrano.fetch(:rollbar_sourcemaps_minified_url_base)
        url_base = "http://#{url_base}" unless url_base.index(/https?:\/\//)
        capistrano.within capistrano.release_path do
          capistrano.within 'public' do
            source_maps = capistrano.capture(:find, '-L', '-name', "'*.js.map'", "-mmin", "-60").split("\n")
            source_maps = source_maps.map { |file| file.gsub(/^\.\//, '') }
            commands = source_maps.map do |source_map|
              minified_url = File.join(url_base, source_map.gsub(/\.map$/, ''))
              "https://api.rollbar.com/api/1/sourcemap -F access_token=#{capistrano.fetch(:rollbar_token)} -F version=#{capistrano.fetch(:current_revision)} -F minified_url=#{minified_url} -F source_map=@#{capistrano.release_path}/public/#{source_map}"
            end
            if commands.length > 0
              cmd = "echo '#{commands.join(' ')}' | xargs -n #{commands.last.split(' ').length} -P 30 curl --silent"
              capistrano.execute(cmd, raise_on_non_zero_exit: false)
            else
              logger.info("no source maps found")
            end
          end
        end
      end
    end
  end
end
