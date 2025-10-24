/**
 * 用户管理相关默认数据工厂函数
 */

import type { 
  UserFormData, 
  RoleFormData, 
  PermissionFormData, 
  LoginFormData, 
  RegisterFormData, 
  ProfileFormData 
} from '../types'

// 创建用户表单默认数据
export const createUserDefaults = (): UserFormData => ({
  name: '',
  email: '',
  password: '',
  status: 'active',
  phone: '',
  department: '',
  position: '',
  role_ids: []
})

// 创建角色表单默认数据
export const createRoleDefaults = (): RoleFormData => ({
  name: '',
  display_name: '',
  description: '',
  permission_ids: []
})

// 创建权限表单默认数据
export const createPermissionDefaults = (): PermissionFormData => ({
  name: '',
  display_name: '',
  description: '',
  resource: '',
  action: '',
  module: ''
})

// 创建登录表单默认数据
export const createLoginDefaults = (): LoginFormData => ({
  email: '',
  password: '',
  remember: false
})

// 创建注册表单默认数据
export const createRegisterDefaults = (): RegisterFormData => ({
  name: '',
  email: '',
  password: '',
  confirm_password: ''
})

// 创建用户资料表单默认数据
export const createProfileDefaults = (): ProfileFormData => ({
  name: '',
  email: '',
  phone: '',
  department: '',
  position: '',
  current_password: '',
  new_password: '',
  confirm_password: ''
})