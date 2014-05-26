require 'pry'
require 'action_mailer'
class Magecap::Notifier
  # @todo: split this into a base notifier class an mail notifier class based on the old-school capistrano-notifier
  def perform
    options =  Capistrano::Configuration.fetch :notifier_mail_options
    notifier =  ActionMailer::Base
    notifier.smtp_settings = options[:smtp_settings]
    notifier.mail({
        :body => html,
        :delivery_method => notifier.delivery_method,
        :from => options[:from],
        :subject => subject,
        :to => options[:to],
        :content_type => 'text/html'
    }).deliver
  end

  def body
    <<-BODY.gsub(/^ {6}/, '')
#{user_name} deployed  #{Capistrano::Configuration.fetch(:application).titleize} branch #{Capistrano::Configuration.fetch(:branch)} to stage #{Capistrano::Configuration.fetch(:stage)}<br/>
      #{Time.now.strftime("%m/%d/%Y")} #{Time.now.strftime("%I:%M %p %Z")}

      <p><strong>#{git_range}</strong>
      #{git_log}</p>
    BODY
  end

  def git_log
    return unless git_range

    `git log #{git_range} --no-merges --format=format:"%h %s (%an)"`
  end

  def git_previous_revision
    Capistrano::Configuration.fetch(:previous_revision)
  end

  def git_current_revision
    Capistrano::Configuration.fetch(:current_revision)
  end

  def git_range
    return unless git_previous_revision && git_current_revision

    "#{git_previous_revision}..#{git_current_revision}"
  end

  def subject
    "#{Capistrano::Configuration.fetch(:application).titleize} branch #{Capistrano::Configuration.fetch(:branch)} deployed to #{Capistrano::Configuration.fetch(:stage)}"
  end

  def github_commit_prefix
    "#{github_prefix}/commits"
  end

  def github_compare_prefix
    "#{github_prefix}/compare"
  end

  def github_prefix
    "https://bitbucket.org/#{github}"
  end

  def github
    Capistrano::Configuration.fetch(:notifier_mail_options)[:github]
  end

  def html
    body.gsub(
        /([0-9a-f]{7})\.\.([0-9a-f]{7})/, "<a href=\"#{github_compare_prefix}/\\1..\\2\">\\1..\\2</a>"
    ).gsub(
        /^([0-9a-f]{7})/, "<br/><a href=\"#{github_commit_prefix}/\\0\">\\0</a>"
    )
  end

  def user_name
    user = ENV['DEPLOYER']
    user = `git config --get user.name`.strip if user.nil?
  end
end
namespace :deploy do
  namespace :notify do
    desc 'Send a deployment notification via email.'
    task :mail do
      Magecap::Notifier.new.perform
      if Capistrano::Configuration.fetch(:notifier_mail_options)[:method] == :test
        puts ActionMailer::Base.deliveries
      end
    end
  end
end
after 'deploy:restart', 'deploy:notify:mail'
