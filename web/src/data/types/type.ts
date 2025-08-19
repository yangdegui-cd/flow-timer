export enum SpaceType {
  FLOW = 'FLOW',
  TASK = 'TASK',
  META_HOST = 'META_HOST',
  META_DATASOURCE = 'META_DATASOURCE',
  META_API = 'META_API',
}

export interface Space {
  id?: string;
  name: string;
  space_type: SpaceType;
  sort: number;
  catalogs: Catalog[];
}

export interface Catalog {
  id?: bigint;
  name: string;
  space_id: string;
  sort: number;
}

export interface FtConfig {
  nodes: any[];
  edges: any[];
}

export interface FtFlow {
  id?: string;
  name: string;
  flow_id?: string;
  description?: string;
  status?: string;
  params?: Record<string, any>;
  version_id?: bigint;
  catalog_id: bigint;
  create_at?: string;
}

export interface FtFlowVersion {
  id?: string;
  flow_id?: string;
  version?: int;
  flow_config: FtConfig;
  create_at?: string;
}

export enum TaskStatus {
  active = 'active',
  paused = 'paused',
  discard = 'discard',
  overdue = 'overdue',
}

export enum TaskType {
  disposable = 'disposable',
  periodic = 'periodic',
  dependent = 'dependent',
}

export interface FtTask {
  id?: number;
  flow_id?: number;
  catalog_id?: number;
  name?: string;
  description: string;
  status: TaskStatus;
  task_type: TaskType;
  period_type?: string;
  cron_expression?: string;
  effective_time?: string;
  lose_efficacy_time?: string
  params?: Record<string, any>;
  queue?: string;
  priority?: number;
  dependents?: string[];
}
