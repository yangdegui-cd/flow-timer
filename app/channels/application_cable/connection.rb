module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # self.current_user = find_verified_user
      Rails.logger.info "ActionCable connected: #{current_user&.email}"
    end

    def disconnect
      Rails.logger.info "ActionCable disconnected: #{current_user&.email}"
    end

    private

    def find_verified_user
      # 简单的验证逻辑，实际应用中应该使用更安全的验证方式
      # 比如 JWT token 验证
      if verified_user = authenticate_user
        verified_user
      else
        # 对于开发环境，允许匿名连接
        if Rails.env.development?
          OpenStruct.new(id: 'anonymous', email: 'anonymous@localhost')
        else
          reject_unauthorized_connection
        end
      end
    end

    def authenticate_user
      # 这里可以实现具体的用户认证逻辑
      # 例如：从 cookies 或 headers 中获取认证信息
      begin
        # 从 cookies 中获取用户信息（简化版本）
        if user_id = cookies.signed[:user_id]
          # 这里应该从数据库查找用户
          # User.find(user_id)
          OpenStruct.new(id: user_id, email: "user#{user_id}@localhost")
        end
      rescue => e
        Rails.logger.error "ActionCable authentication error: #{e.message}"
        nil
      end
    end
  end
end
