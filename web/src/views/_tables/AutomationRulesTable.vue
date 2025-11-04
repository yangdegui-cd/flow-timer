<script setup lang="ts">
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import ToggleButton from 'primevue/togglebutton'
import Button from 'primevue/button'
import type { AutomationRule } from '@/api/automation-rule-api'

interface FormattedRule extends AutomationRule {
  condition: string
  actionDisplay: string
}

interface Props {
  rules: FormattedRule[]
  loading?: boolean
}

interface Emits {
  (e: 'toggle', rule: AutomationRule): void
  (e: 'edit', rule: AutomationRule): void
  (e: 'delete', ruleId: number): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const handleToggle = (rule: AutomationRule) => {
  emit('toggle', rule)
}

const handleEdit = (rule: AutomationRule) => {
  emit('edit', rule)
}

const handleDelete = (ruleId: number) => {
  emit('delete', ruleId)
}
</script>

<template>
  <DataTable
      :value="rules"
      :loading="loading"
      size="small"
  >
    <Column field="name" header="规则名称"/>
    <Column field="condition" header="触发条件"/>
    <Column field="actionDisplay" header="执行动作"/>
    <Column header="状态" style="width: 120px">
      <template #body="{ data }">
        <ToggleButton
            v-model="data.enabled"
            @change="handleToggle(data)"
            onLabel="启用"
            offLabel="禁用"
            size="small"
        />
      </template>
    </Column>
    <Column header="操作" style="width: 150px">
      <template #body="{ data }">
        <div class="flex gap-2">
          <Button
              @click="handleEdit(data)"
              icon="pi pi-pencil"
              size="small"
              severity="secondary"
              text
          />
          <Button
              @click="handleDelete(data.id)"
              icon="pi pi-trash"
              size="small"
              severity="danger"
              text
          />
        </div>
      </template>
    </Column>
    <template #empty>
      <div class="text-center py-4 text-gray-500">
        暂无自动化规则
      </div>
    </template>
  </DataTable>
</template>
