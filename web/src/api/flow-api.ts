import request from "@/request";

export function ApiGetFlowCurrentVersion(id) {
  return request({
    url: "/ft_flow/current_version",
    method: 'get',
    params: { id }
  });
}
export function ApiGetFlowTreeList() {
  return request({
    url: "/ft_flow/get_tree_list",
    method: 'get',
  });
}

// 获取流程统计信息
export function ApiGetFlowStatistics(catalogIds?: number[]) {
  return request({
    url: "/ft_flow/statistics",
    method: 'get',
    params: { catalog_ids: catalogIds }
  });
}

// 批量更新流程状态
export function ApiBatchUpdateFlowStatus(flowIds: number[], status: string) {
  return request({
    url: "/ft_flow/batch_update_status",
    method: 'patch',
    data: { 
      flow_ids: flowIds,
      status: status
    }
  });
}

// 批量删除流程
export function ApiBatchDeleteFlows(flowIds: number[]) {
  return request({
    url: "/ft_flow/batch_delete",
    method: 'delete',
    data: { 
      flow_ids: flowIds
    }
  });
}
