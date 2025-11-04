import { onMounted, Ref } from "vue";
import { AdsDimension, AdsMetric } from "@/data/types/ads-types";
import metricsApi, { DimensionResult } from "@/api/metrics-api";
import { defineStore } from "pinia";

export const useMetricsStore = defineStore("metrics", () => {
  const metrics: Ref<AdsMetric[]> = ref([]);
  const loading: Ref<boolean> | null = ref(false);
  const dimensions: Ref<DimensionResult[]> = ref([])

  const loadMetrics = () => {
    loading.value = true
    if (unref(metrics).length > 0) return loading.value = false
    metricsApi.list()
      .then(res => metrics.value = res)
      .catch(err => console.error('加载指标失败:', err))
      .finally(() => loading.value = false);
  }

  const loadDimensions = () => {
    loading.value = true
    if (Object.keys(unref(dimensions)).length > 0) return loading.value = false
    metricsApi.listDimensions()
      .then(res => dimensions.value = res)
      .catch(err => console.error('加载维度失败:', err))
      .finally(() => loading.value = false);
  }

  const getMetric = (key: string): AdsMetric | undefined => metrics.value.find(metric => metric.key === key)
  const getMetricName = (key: string): string | undefined => getMetric(key)?.display_name
  const getDimension = (name: string): AdsDimension | undefined => {
    for (const dimCategory of dimensions.value) {
      let dim = dimCategory.dimensions.find(d => d.name === name)
      if (dim) return dim
    }
    return undefined
  }
  const getDimCategory = (name: string): string | undefined => getDimension(name)?.category

  onMounted(() => {
    loadMetrics()
    loadDimensions()
  });

  return {
    //state
    metrics,
    dimensions,
    loading,

    //actions
    loadMetrics,
    getMetric,
    getMetricName,
    getDimension,
    getDimCategory
  }
})
