import { onMounted, Ref } from "vue";
import { AdsMetric } from "@/data/types/ads-types";
import metricsApi from "@/api/metrics-api";

export const useMetrics = (toast) => {
  const metrics: Ref<AdsMetric[]> = ref([]);
  const loading: Ref<boolean> | null = ref(false);

  const loadMetrics = () => {
    loading.value = true
    if (unref(metrics).length > 0) return loading.value = false

    metricsApi.list()
      .then(res => {
        metrics.value = res
      })
      .catch(err => {
        toast.add({ severity: 'error', summary: '错误', detail: err.msg, life: 3000 })
      })
      .finally(() => {
        loading.value = false
      });
  }

  const getMetric = (key: string): AdsMetric | undefined => unref(metrics).find(metric => metric.key === key)
  const getMetricName = (key: string): string | undefined => getMetric(key)?.display_name

  onMounted(() => loadMetrics());

  return {
    metrics,
    loading,
    loadMetrics,
    getMetric,
    getMetricName
  }
}
