import { ref } from 'vue'
import { Node } from '@vue-flow/core'

export interface LayoutResult {
  nodes: Node[]
  success: boolean
  message: string
}

/**
 * Flow布局Composable - 专注于节点对齐和分布功能
 */
export function useFlowLayout() {
  const isLayouting = ref(false)

  /**
   * 对齐节点
   */
  function alignNodes(nodes: Node[], alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom'): LayoutResult {
    try {
      if (nodes.length === 0) {
        return { nodes, success: true, message: '无节点需要对齐' }
      }

      const positions = nodes.map(node => node.position)
      let newNodes: Node[]

      switch (alignment) {
        case 'left':
          const minX = Math.min(...positions.map(pos => pos.x))
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, x: minX }
          }))
          break

        case 'right':
          const maxX = Math.max(...positions.map(pos => pos.x))
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, x: maxX }
          }))
          break

        case 'center':
          const avgX = positions.reduce((sum, pos) => sum + pos.x, 0) / positions.length
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, x: avgX }
          }))
          break

        case 'top':
          const minY = Math.min(...positions.map(pos => pos.y))
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, y: minY }
          }))
          break

        case 'bottom':
          const maxY = Math.max(...positions.map(pos => pos.y))
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, y: maxY }
          }))
          break

        case 'middle':
          const avgY = positions.reduce((sum, pos) => sum + pos.y, 0) / positions.length
          newNodes = nodes.map(node => ({
            ...node,
            position: { ...node.position, y: avgY }
          }))
          break

        default:
          newNodes = nodes
      }

      return {
        nodes: newNodes,
        success: true,
        message: `成功对齐 ${newNodes.length} 个节点到${alignment}`
      }
    } catch (error) {
      return {
        nodes,
        success: false,
        message: `对齐失败: ${error instanceof Error ? error.message : '未知错误'}`
      }
    }
  }

  /**
   * 分布节点 - 在指定方向上均匀分布
   */
  function distributeNodes(nodes: Node[], direction: 'horizontal' | 'vertical'): LayoutResult {
    try {
      if (nodes.length <= 2) {
        return { nodes, success: true, message: '需要至少3个节点才能分布' }
      }

      const sortedNodes = [...nodes].sort((a, b) => {
        return direction === 'horizontal' ? 
          a.position.x - b.position.x : 
          a.position.y - b.position.y
      })

      const first = sortedNodes[0]
      const last = sortedNodes[sortedNodes.length - 1]
      
      const totalDistance = direction === 'horizontal' ? 
        last.position.x - first.position.x :
        last.position.y - first.position.y
        
      const spacing = totalDistance / (sortedNodes.length - 1)

      const newNodes = sortedNodes.map((node, index) => ({
        ...node,
        position: {
          ...node.position,
          [direction === 'horizontal' ? 'x' : 'y']: 
            (direction === 'horizontal' ? first.position.x : first.position.y) + index * spacing
        }
      }))

      return {
        nodes: newNodes,
        success: true,
        message: `成功${direction === 'horizontal' ? '水平' : '垂直'}分布 ${newNodes.length} 个节点`
      }
    } catch (error) {
      return {
        nodes,
        success: false,
        message: `分布失败: ${error instanceof Error ? error.message : '未知错误'}`
      }
    }
  }

  return {
    isLayouting,
    alignNodes,
    distributeNodes
  }
}