import { defineStore } from "pinia"
import { onMounted, Ref } from "vue"
import projectApi from "@/api/project-api"
import adsDataApi from "@/api/ads-data-api"

interface Project {
  id: number
  name: string

  [key: string]: any
}

interface AdsAccount {
  id: number
  name: string
  platform: string

  [key: string]: any
}

export const useCommonDataStore = defineStore("commonData", () => {
  // State
  const projects: Ref<Project[]> = ref([])
  const adsAccounts: Ref<AdsAccount[]> = ref([])
  const loading: Ref<boolean> = ref(false)

  // Platform 映射
  const platformMap: Record<string, string> = {
    facebook: 'Facebook',
    google: 'Google',
    tiktok: 'TikTok',
    twitter: 'Twitter',
    instagram: 'Instagram',
    linkedin: 'LinkedIn'
  }

  // Actions
  const loadProjects = (reload = false) => {
    if (projects.value.length > 0 && !reload) return

    loading.value = true
    projectApi.list()
      .then(data => projects.value = data)
      .catch(err => console.error('加载项目列表失败:', err))
      .finally(() => loading.value = false)
  }

  const loadAdsAccounts = (reload = false) => {
    if (adsAccounts.value.length > 0 && !reload) return
    loading.value = true
    adsDataApi.getAccounts()
      .then((data) => adsAccounts.value = data)
      .catch(err => console.error('加载账号列表失败:', err))
      .finally(() => loading.value = false)
  }

  const getProject = (projectId: number): Project | undefined => {
    return projects.value.find(p => p.id === projectId)
  }

  const getProjectName = (projectId: number | null | undefined): string => {
    return getProject(projectId)?.name || `项目#${projectId}`
  }

  const getAdsAccount = (accountId: number): AdsAccount | undefined => {
    return adsAccounts.value.find(a => a.id === accountId)
  }

  const getAdsAccountsByProject = (projectId: number): AdsAccount[] => {
    return adsAccounts.value.filter(a => a.project_id === projectId)
  }

  const getAvailableAdsAccounts = (projectId: number): AdsAccount[] => {
    return adsAccounts.value.filter(a => {
      return a.project_id === projectId || !a.project_id
    })
  }

  const getAdsAccountName = (accountId: number | null | undefined): string => {
    return getAdsAccount(accountId)?.name || `账号#${accountId}`
  }

  const getPlatformName = (platform: string | null | undefined): string => {
    if (!platform) return '-'
    return platformMap[platform.toLowerCase()] || platform
  }

  // 初始化时加载数据
  onMounted(() => {
    loadProjects()
    loadAdsAccounts()
  })

  return {
    // State
    projects,
    adsAccounts,
    loading,

    // Actions
    loadProjects,
    loadAdsAccounts,

    // Getters
    getProjectName,
    getAdsAccountName,
    getAvailableAdsAccounts,
    getAdsAccountsByProject,
    getPlatformName,
    getProject,
    getAdsAccount
  }
})
