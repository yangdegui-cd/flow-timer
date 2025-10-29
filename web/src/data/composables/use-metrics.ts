import { onMounted, Ref } from "vue";
import { Metric } from "@/data/types/ads-types";
import metricsApi from "@/api/metrics-api";

export const useMetrics = (metrics: Ref<Metric[]>, toast, loading?: Ref<boolean>) => {
  const loadMetrics = () => {
    loading?.value = true;
    metricsApi.list()
      .then(res => {
        metrics.value = res
      })
      .catch(err => {
        toast.add({ severity: 'err', summary: '错误', detail: err.msg, life: 3000 })
      })
      .finally(() => {
        loading?.value = false;
      });
  }

  onMounted(() => loadMetrics());

  return {
    loadMetrics
  }
}
