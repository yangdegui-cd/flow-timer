# frozen_string_literal: true

module Result
  def ok(data = nil, msg = "")
    { code: 200, data: data, msg: msg }
  end

  def not_login
    { code: 401, msg: "请先登录" }
  end

  def overdue_code
    { code: 304, msg: "验证码错误或已过期" }
  end

  def password_wrong
    { code: 302, msg: "账号或者密码错误" }
  end

  def not_choose_project
    { code: 303, msg: "请先选择项目" }
  end

  def not_has_permission(perm)
    { code: 351, msg: "缺少权限: #{perm}" }
  end

  def error(msg)
    { code: 400, msg: msg }
  end
end
