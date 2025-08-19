import { TaskStatus, TaskType } from "@/data/types/type";

export const initDefaultTaskValue =() => {
  return {
    id: null,
    flow_id: null,
    catalog_id: null,
    name: null,
    description: null,
    status: TaskStatus.paused,
    task_type: TaskType.periodic,
    period_type: null,
    cron_expression: '',
    effective_time: null,
    lose_efficacy_time: null,
    params: {},
    queue: 'default',
    priority: 1,
    dependents: [],
  }
}
