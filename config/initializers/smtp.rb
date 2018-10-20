if Rails.env.staging?
  ActionMailer::Base.smtp_settings = {
    address:              'smtp.mailgun.org',
    port:                 '587',
    authentication:       :plain,
    user_name:            ENV['MAILGUN_USERNAME'],
    password:             ENV['MAILGUN_PASSWORD'],
    domain:               ENV['MAILGUN_DOMAIN'],
    enable_starttls_auto: true
  }
end
