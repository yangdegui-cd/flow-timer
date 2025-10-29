class QyWechatWebhookService

  def self.send_message(body)
    config = Config.first
    key = config&.qy_wechat_notification_key
    url = config&.qy_wechat_notification_url || "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
    uri = URI.parse("#{url}?key=#{key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    req.body = body
    http.request(req)
  end

  def self.send_text_message(text, mentioned_list = [], mentioned_mobile_list = [])
    body = {
      "msgtype": "text",
      "text": {
        "content": text,
        "mentioned_list": mentioned_list,
        "mentioned_mobile_list": mentioned_mobile_list
      }
    }.to_json
    send_message(body)
  end

  def self.send_markdown_message(title, text, mentioned_list = [], mentioned_mobile_list = [])
    body = {
      "msgtype": "markdown",
      "markdown": {
        "content": "#{title}\n\n#{text}",
        "mentioned_list": mentioned_list,
        "mentioned_mobile_list": mentioned_mobile_list
      }
    }.to_json
    send_message(body)
  end
end
