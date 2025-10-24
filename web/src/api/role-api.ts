import { BaseApi } from './base-api'
import type {
  AvailablePermissionsResponse,
  RoleOperationResponse,
  UpdatePermissionsRequest
} from '@/data/types/role-types'

// 角色API类
export class RoleApi extends BaseApi {
  constructor() {
    super('sys_role')
  }

  // 更新角色权限
  async updatePermissions(id: number, data: UpdatePermissionsRequest): Promise<RoleOperationResponse> {
    return this.put<RoleOperationResponse>(`${id}/update_permissions`, data)
  }
}

// 导出单例实例
const roleApi = new RoleApi()
export default roleApi
