/**
 * COS 相关默认数据配置
 */

import type { 
  CosFormData, 
  CosUploadSetting, 
  SourceSetting,
  UploadCosConfig 
} from '@/data/types/cos-types'

// COS 表单默认数据
export const createCosFormDefaults = (): CosFormData => ({
  name: '',
  description: '',
  region: 'ap-guangzhou',
  secret_id: '',
  secret_key: '',
  bucket: '',
  prefix: '',
  storage_class: 'STANDARD',
  acl: 'private',
  use_ssl: true,
  environment: 'development',
  tags: '',
  notes: ''
})

// COS 上传设置默认数据
export const createCosUploadDefaults = (): CosUploadSetting => ({
  config_type: 'manual',
  meta_cos_id: null,
  region: 'ap-guangzhou',
  secret_id: '',
  secret_key: '',
  bucket: '',
  prefix: '',
  storage_class: 'STANDARD',
  acl: 'private',
  overwrite: true,
  use_ssl: true
})

// 源文件设置默认数据
export const createSourceSettingDefaults = (): SourceSetting => ({
  source_type: 'custom',
  host_setting: {
    host: '',
    port: 22,
    username: '',
    authentication_type: 'password',
    password: '',
    pem: ''
  },
  choose_host: null,
  files: [],
  multifile_merge: true,
  use_original_name: false,
  use_zip: false,
  tmp_folder: null,
  file_name: null
})

// COS 上传节点完整配置默认数据
export const createUploadCosConfigDefaults = (): UploadCosConfig => ({
  source_setting: createSourceSettingDefaults(),
  cos_setting: createCosUploadDefaults()
})