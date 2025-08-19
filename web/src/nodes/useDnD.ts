import { useVueFlow } from '@vue-flow/core'
import { type Ref, ref, watch } from 'vue'
import nodes_setting from "@/nodes/nodes-setting.ts";


/**
 * @returns {string} - A uuid.
 */
function getId() {
  return crypto.randomUUID();
}

/**
 * In a real world scenario you'd want to avoid creating refs in a global scope like this as they might not be cleaned up properly.
 * @type {{draggedType: Ref<string|null>, isDragOver: Ref<boolean>, isDragging: Ref<boolean>}}
 */
const state: {
  nodeType: Ref<string | null>
  isDragOver: Ref<boolean>
  isDragging: Ref<boolean>
}  = {
  nodeType: ref(null),
  isDragOver: ref(false),
  isDragging: ref(false),
}

export default function useDragAndDrop() {
  const { nodeType, isDragOver, isDragging } = state

  const { addNodes, screenToFlowCoordinate, onNodesInitialized, updateNode } = useVueFlow()

  watch(isDragging, (dragging) => {
    document.body.style.userSelect = dragging ? 'none' : ''
  })

  function onDragStart(event: any, type: string) {
    if (event.dataTransfer) {
      event.dataTransfer.setData('application/vueflow', type)
      event.dataTransfer.effectAllowed = 'move'
    }

    nodeType.value = type
    isDragging.value = true

    document.addEventListener('drop', onDragEnd)
  }

  /**
   * Handles the drag over event.
   *
   * @param {DragEvent} event
   */
  function onDragOver(event: any) {
    event.preventDefault()

    if (nodeType.value) {
      isDragOver.value = true

      if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move'
      }
    }
  }

  function onDragLeave() {
    isDragOver.value = false
  }

  function onDragEnd() {
    isDragging.value = false
    isDragOver.value = false
    nodeType.value = null
    document.removeEventListener('drop', onDragEnd)
  }

  /**
   * Handles the drop event.
   *
   * @param {DragEvent} event
   */
  function onDrop(event: any) {
    const position = screenToFlowCoordinate({
      x: event.clientX,
      y: event.clientY,
    })

    const nodeId = getId()
    const nodeSetting = nodes_setting[nodeType.value as string]
    const newNode = {
      id: nodeId,
      type: nodeSetting.view.node_type,
      position,
      data: {
        label: nodeSetting.view.name,
        node_type: nodeType.value,
        config: nodeSetting.init
      },
    }

    /**
     * Align node position after drop, so it's centered to the mouse
     *
     * We can hook into events even in a callback, and we can remove the event listener after it's been called.
     */
    const { off } = onNodesInitialized(() => {
      updateNode(nodeId, (node) =>{
        console.log( node.dimensions.width)
        console.log( node.dimensions.height)
        return {
          position: { x: node.position.x - node.dimensions.width / 2, y: node.position.y - node.dimensions.height / 2 },
        }
      })
      off()
    })
    addNodes(newNode)
  }

  return {
    draggedType: nodeType,
    isDragOver,
    isDragging,
    onDragStart,
    onDragLeave,
    onDragOver,
    onDrop,
  }
}
