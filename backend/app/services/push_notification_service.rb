require 'webpush'

class PushNotificationService
  def initialize(subscription)
    @subscription = subscription
  end

  def send_notification(title, body, data = {})
    payload = {
      title: title,
      body: body,
      data: data,
      # icon: '/icons/icon-192x192.png', # Optional
    }.to_json

    # Ensure VAPID subject matches exactly
    options = {
      vapid: {
        subject: 'mailto:karloszuru@gmail.com',
        public_key: vapid_public_key,
        private_key: vapid_private_key,
      },
      ttl: 60,
    }

    begin
      # Log VAPID key details for debugging
      Rails.logger.debug("VAPID Public Key: #{options[:vapid][:public_key].present? ? 'Loaded' : 'Missing'}")
      Rails.logger.debug("VAPID Private Key: #{options[:vapid][:private_key].present? ? 'Loaded' : 'Missing'}")
      Rails.logger.debug("VAPID Subject: #{options[:vapid][:subject]}")

      response = Webpush.payload_send(
        message: payload,
        endpoint: @subscription.endpoint,
        p256dh: @subscription.p256dh_key,
        auth: @subscription.auth_key,
        vapid: options[:vapid],
        ttl: options[:ttl]
      )

      if response.code.between?(200, 299)
        Rails.logger.info("Push notification sent successfully to subscription ID: #{@subscription.id}")
        return { success: true }
      else
        Rails.logger.error("Push notification failed with status #{response.code} for subscription ID: #{@subscription.id}")
        handle_failed_push(response.code)
      end
    rescue Webpush::ExpiredSubscription => e
      Rails.logger.warn("Expired subscription (ID: #{@subscription.id}): #{e.message}")
      @subscription.destroy
      return { success: false, error: "Expired subscription and has been removed." }
    rescue Webpush::InvalidSubscription => e
      Rails.logger.warn("Invalid subscription (ID: #{@subscription.id}): #{e.message}")
      @subscription.destroy
      return { success: false, error: "Invalid subscription and has been removed." }
    rescue => e
      Rails.logger.error("An error occurred while sending push notification to subscription ID: #{@subscription.id} - #{e.message}")
      return { success: false, error: "An error occurred: #{e.message}" }
    end
  end

  private

  def vapid_public_key
    key = ENV['VAPID_PUBLIC_KEY'] || Rails.application.credentials.webpush[:public_key]
    Rails.logger.debug("Loaded VAPID Public Key from #{ENV['VAPID_PUBLIC_KEY'] ? 'ENV' : 'Rails credentials'}")
    key
  end

  def vapid_private_key
    key = ENV['VAPID_PRIVATE_KEY'] || Rails.application.credentials.webpush[:private_key]
    Rails.logger.debug("Loaded VAPID Private Key from #{ENV['VAPID_PRIVATE_KEY'] ? 'ENV' : 'Rails credentials'}")
    key
  end

  def handle_failed_push(status_code)
    if [410, 404].include?(status_code.to_i)
      Rails.logger.warn("Subscription expired or invalid (status #{status_code}) for subscription ID: #{@subscription.id}, removing...")
      @subscription.destroy
      return { success: false, status: status_code.to_i, error: "Subscription expired or invalid (status #{status_code}) and has been removed." }
    else
      Rails.logger.error("Push failed with status #{status_code} for subscription ID: #{@subscription.id}")
      return { success: false, status: status_code.to_i, error: "Push failed with status #{status_code}" }
    end
  end
end
