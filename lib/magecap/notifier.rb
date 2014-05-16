require 'capistrano/notifier/mail'
class Capistrano::Notifier::AvidMail < Capistrano::Notifier::Mail
  def perform
    notifier =  ActionMailer::Base
    notifier.smtp_settings = smtp_settings
    notifier.mail({
        :body => html,
        :delivery_method => notifier.delivery_method,
        :from => from,
        :subject => subject,
        :to => to,
        :content_type => 'text/html'
    }).deliver
  end

  def body
    <<-BODY.gsub(/^ {6}/, '')
#{user_name} deployed  #{application.titleize} branch #{branch} to stage #{stage}<br/>
      #{now.strftime("%m/%d/%Y")} #{now.strftime("%I:%M %p %Z")}

      <p><strong>#{git_range}</strong>
      #{git_log}</p>
    BODY
  end

  def github_commit_prefix
    "#{github_prefix}/commits"
  end

  def github_prefix
    "https://bitbucket.org/#{github}"
  end

  def html
    body.gsub(
        /([0-9a-f]{7})\.\.([0-9a-f]{7})/, "<a href=\"#{github_compare_prefix}/\\1..\\2\">\\1..\\2</a>"
    ).gsub(
        /^([0-9a-f]{7})/, "<br/><a href=\"#{github_commit_prefix}/\\0\">\\0</a>"
    )
  end
end
namespace :deploy do
  namespace :notify do
    desc 'Send a deployment notification via email.'
    task :mail do
      Capistrano::Notifier::AvidMail.new(configuration).perform
      if configuration.notifier_mail_options[:method] == :test
        puts ActionMailer::Base.deliveries
      end
    end
  end
end
after 'deploy:restart', 'deploy:notify:mail'
