<script setup lang="ts">

import Card from "primevue/card";
import Button from "primevue/button";
import AdsAccountsTable from "@/views/_tables/AdsAccountsTable.vue";
import { useCommonDataStore } from "@/stores/common-data";
import AdsAccountSelector from "@/views/_selector/AdsAccountSelector.vue";
import { computed, ref } from "vue";
import { adsAccountApi } from "@/api/ads-account-api";
import { useToast } from "primevue/usetoast";
import { useConfirm } from "primevue/useconfirm";

const confirm = useConfirm()
const toast = useToast()
const commonDataStore = useCommonDataStore()
const { getAvailableAdsAccounts, loadAdsAccounts, getAdsAccountsByProject } = commonDataStore

const props = defineProps<{
  project: any
}>()
const bindedAdsAccounts = computed(() => getAdsAccountsByProject(props.project.id))
const selectedAdsAccounts = ref([])

//绑定账号
const bindAdsAccounts =async () => {
  if (!selectedAdsAccounts.value || selectedAdsAccounts.value.length === 0) {
    return toast.add({ severity: 'warn', summary: '提示', detail: '请选择要绑定的账户', life: 3000 })
  }

  try {
    for (const accountId of selectedAdsAccounts.value) {
      await adsAccountApi.bindAccount(props.project.id, accountId)
    }

    toast.add({ severity: 'success', summary: '成功', detail: '广告账户绑定成功', life: 3000 })
    selectedAdsAccounts.value = []
    loadAdsAccounts(true)
  } catch (err: any) {
    console.error('绑定广告账户失败:', err)
    const message = err?.msg ?? '绑定失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 解绑广告账户
const unbindAdsAccount = (accountId: number) => {
  confirm.require({
    message: '确定要解绑该广告账户吗？解绑后该账户将不再与此项目关联。',
    header: '确认解绑',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '确定',
    rejectLabel: '取消',
    accept: async () => {
      adsAccountApi.unbindAccount(props.project.id, accountId)
          .then(async () => {
            toast.add({ severity: 'success', summary: '成功', detail: '广告账户解绑成功', life: 3000 })
            loadAdsAccounts(true)
          })
          .catch((err: any) => {
            console.error('解绑广告账户失败:', err)
            toast.add({ severity: 'error', summary: '错误', detail: err?.msg ?? '解绑失败', life: 3000 })
          })
    }
  })
}
</script>

<template>
  <Card>
    <template #title>
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <i class="pi pi-link text-green-600 mr-2"/>绑定广告账户
        </div>
        <Button @click="bindAdsAccounts" size="small" class="flex items-center">
          <i class="pi pi-plus mr-2"/>绑定账户
        </Button>
      </div>
    </template>

    <template #content>
      <div class="space-y-4">
        <AdsAccountSelector v-model="selectedAdsAccounts"
                            :options="getAvailableAdsAccounts(project.id)"
                            multiple
                            placeholder="选择要绑定的广告账户"
                            class="w-full"/>
        <AdsAccountsTable :accounts="bindedAdsAccounts" @unbind="unbindAdsAccount"/>
      </div>
    </template>
  </Card>
</template>

<style scoped>

</style>
