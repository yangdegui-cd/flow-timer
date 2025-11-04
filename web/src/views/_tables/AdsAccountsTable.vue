<script setup lang="ts">
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import Button from 'primevue/button'

interface AdsAccount {
  id: number
  name: string
  account_id: string
  account_status: string
  ads_platform?: {
    name: string
  }
}

interface Props {
  accounts: AdsAccount[]
}

interface Emits {
  (e: 'unbind', accountId: number): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const handleUnbind = (accountId: number) => {
  emit('unbind', accountId)
}
</script>

<template>
  <DataTable
      :value="accounts"
      size="small"
  >
    <Column field="name" header="账户名称"/>
    <Column field="ads_platform.name" header="平台">
      <template #body="{ data }">
        <Tag :value="data.ads_platform?.name || '未知平台'" severity="info"/>
      </template>
    </Column>
    <Column field="account_id" header="账户ID"/>
    <Column field="account_status" header="状态">
      <template #body="{ data }">
        <Tag
            :value="data.account_status === 'active' ? '活跃' : data.account_status === 'suspended' ? '暂停' : '关闭'"
            :severity="data.account_status === 'active' ? 'success' : 'warning'"
        />
      </template>
    </Column>
    <Column header="操作" style="width: 100px">
      <template #body="{ data }">
        <Button
            icon="pi pi-trash"
            size="small"
            severity="danger"
            text
            @click="handleUnbind(data.id)"
            title="解绑账户"
        />
      </template>
    </Column>
    <template #empty>
      <div class="text-center py-4 text-gray-500">
        暂未绑定广告账户
      </div>
    </template>
  </DataTable>
</template>
