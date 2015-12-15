ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  :server => 'email.eu-west-1.amazonaws.com',
  :access_key_id     => DATABASE['amazon_ses']['api_key'],
  :secret_access_key => DATABASE['amazon_ses']['api_secret']

