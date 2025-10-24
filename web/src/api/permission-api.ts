import { BaseApi } from './base-api'
import type {
  AvailablePermissionsResponse,
  RoleOperationResponse,
  UpdatePermissionsRequest
} from '@/data/types/role-types'

// 角色API类
export class PermissionApi extends BaseApi {
  constructor() {
    super('sys_permission')
  }
}

// 导出单例实例
const permissionApi = new PermissionApi()
export default permissionApi
