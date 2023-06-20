# ``OBSAsyncAPI/OBSClient``

## Topics

### Connecting

- ``init(hostname:port:connectTimeout:password:eventSubscriptions:)``
- ``connect()``
- ``isConnected``
- ``connectTimeout``

### Events

- ``events``
- ``eventSubscriptions``

### General Requests

- ``getVersion()``
- ``getStats()``
- ``broadcastCustomEvent(eventData:)``
- ``callVendorRequest(vendorName:requestType:requestData:)``
- ``getHotkeyList()``
- ``triggerHotkeyByName(hotkeyName:)``
- ``triggerHotkeyByKeySequence(keyId:keyModifiers:)``
- ``sleep(sleepMillis:sleepFrames:)``


### Scene Requests

- ``getSceneList()``
- ``getGroupList()``
- ``getCurrentProgramScene()``
- ``setCurrentProgramScene(sceneName:)``
- ``getCurrentPreviewScene()``
- ``setCurrentPreviewScene(sceneName:)``
- ``createScene(sceneName:)``
- ``removeScene(sceneName:)``
- ``setSceneName(sceneName:newSceneName:)``
- ``getSceneSceneTransitionOverride(sceneName:)``
- ``setSceneSceneTransitionOverride(sceneName:transitionName:transitionDuration:)``


### Record Requests

- ``getRecordStatus()``
- ``toggleRecord()``
- ``startRecord()``
- ``stopRecord()``
- ``toggleRecordPause()``
- ``pauseRecord()``
- ``resumeRecord()``


### Config Requests

- ``getPersistentData(realm:slotName:)``
- ``setPersistentData(realm:slotName:slotValue:)``
- ``getSceneCollectionList()``
- ``setCurrentSceneCollection(sceneCollectionName:)``
- ``createSceneCollection(sceneCollectionName:)``
- ``getProfileList()``
- ``setCurrentProfile(profileName:)``
- ``createProfile(profileName:)``
- ``removeProfile(profileName:)``
- ``getProfileParameter(parameterCategory:parameterName:)``
- ``setProfileParameter(parameterCategory:parameterName:parameterValue:)``
- ``getVideoSettings()``
- ``setVideoSettings(fpsNumerator:fpsDenominator:baseWidth:baseHeight:outputWidth:outputHeight:)``
- ``getStreamServiceSettings()``
- ``setStreamServiceSettings(streamServiceType:streamServiceSettings:)``
- ``getRecordDirectory()``


### Source Requests

- ``getSourceActive(sourceName:)``
- ``getSourceScreenshot(sourceName:imageFormat:imageWidth:imageHeight:imageCompressionQuality:)``
- ``saveSourceScreenshot(sourceName:imageFormat:imageFilePath:imageWidth:imageHeight:imageCompressionQuality:)``


### UI Requests

- ``getStudioModeEnabled()``
- ``setStudioModeEnabled(studioModeEnabled:)``
- ``openInputPropertiesDialog(inputName:)``
- ``openInputFiltersDialog(inputName:)``
- ``openInputInteractDialog(inputName:)``
- ``getMonitorList()``
- ``openVideoMixProjector(videoMixType:monitorIndex:projectorGeometry:)``
- ``openSourceProjector(sourceName:monitorIndex:projectorGeometry:)``


### Filter Requests

- ``getSourceFilterList(sourceName:)``
- ``getSourceFilterDefaultSettings(filterKind:)``
- ``createSourceFilter(sourceName:filterName:filterKind:filterSettings:)``
- ``removeSourceFilter(sourceName:filterName:)``
- ``setSourceFilterName(sourceName:filterName:newFilterName:)``
- ``getSourceFilter(sourceName:filterName:)``
- ``setSourceFilterIndex(sourceName:filterName:filterIndex:)``
- ``setSourceFilterSettings(sourceName:filterName:filterSettings:overlay:)``
- ``setSourceFilterEnabled(sourceName:filterName:filterEnabled:)``


### Output Requests

- ``getVirtualCamStatus()``
- ``toggleVirtualCam()``
- ``startVirtualCam()``
- ``stopVirtualCam()``
- ``getReplayBufferStatus()``
- ``toggleReplayBuffer()``
- ``startReplayBuffer()``
- ``stopReplayBuffer()``
- ``saveReplayBuffer()``
- ``getLastReplayBufferReplay()``
- ``getOutputList()``
- ``getOutputStatus(outputName:)``
- ``toggleOutput(outputName:)``
- ``startOutput(outputName:)``
- ``stopOutput(outputName:)``
- ``getOutputSettings(outputName:)``
- ``setOutputSettings(outputName:outputSettings:)``


### Scene Item Requests

- ``getSceneItemList(sceneName:)``
- ``getGroupSceneItemList(sceneName:)``
- ``getSceneItemId(sceneName:sourceName:searchOffset:)``
- ``createSceneItem(sceneName:sourceName:sceneItemEnabled:)``
- ``removeSceneItem(sceneName:sceneItemId:)``
- ``duplicateSceneItem(sceneName:sceneItemId:destinationSceneName:)``
- ``getSceneItemTransform(sceneName:sceneItemId:)``
- ``setSceneItemTransform(sceneName:sceneItemId:sceneItemTransform:)``
- ``getSceneItemEnabled(sceneName:sceneItemId:)``
- ``setSceneItemEnabled(sceneName:sceneItemId:sceneItemEnabled:)``
- ``getSceneItemLocked(sceneName:sceneItemId:)``
- ``setSceneItemLocked(sceneName:sceneItemId:sceneItemLocked:)``
- ``getSceneItemIndex(sceneName:sceneItemId:)``
- ``setSceneItemIndex(sceneName:sceneItemId:sceneItemIndex:)``
- ``getSceneItemBlendMode(sceneName:sceneItemId:)``
- ``setSceneItemBlendMode(sceneName:sceneItemId:sceneItemBlendMode:)``


### Media Input Requests

- ``getMediaInputStatus(inputName:)``
- ``setMediaInputCursor(inputName:mediaCursor:)``
- ``offsetMediaInputCursor(inputName:mediaCursorOffset:)``
- ``triggerMediaInputAction(inputName:mediaAction:)``


### Stream Requests

- ``getStreamStatus()``
- ``toggleStream()``
- ``startStream()``
- ``stopStream()``
- ``sendStreamCaption(captionText:)``


### Transition Requests

- ``getTransitionKindList()``
- ``getSceneTransitionList()``
- ``getCurrentSceneTransition()``
- ``setCurrentSceneTransition(transitionName:)``
- ``setCurrentSceneTransitionDuration(transitionDuration:)``
- ``setCurrentSceneTransitionSettings(transitionSettings:overlay:)``
- ``getCurrentSceneTransitionCursor()``
- ``triggerStudioModeTransition()``
- ``setTBarPosition(position:release:)``


### Input Requests

- ``getInputList(inputKind:)``
- ``getInputKindList(unversioned:)``
- ``getSpecialInputs()``
- ``createInput(sceneName:inputName:inputKind:inputSettings:sceneItemEnabled:)``
- ``removeInput(inputName:)``
- ``setInputName(inputName:newInputName:)``
- ``getInputDefaultSettings(inputKind:)``
- ``getInputSettings(inputName:)``
- ``setInputSettings(inputName:inputSettings:overlay:)``
- ``getInputMute(inputName:)``
- ``setInputMute(inputName:inputMuted:)``
- ``toggleInputMute(inputName:)``
- ``getInputVolume(inputName:)``
- ``setInputVolume(inputName:inputVolumeMul:inputVolumeDb:)``
- ``getInputAudioBalance(inputName:)``
- ``setInputAudioBalance(inputName:inputAudioBalance:)``
- ``getInputAudioSyncOffset(inputName:)``
- ``setInputAudioSyncOffset(inputName:inputAudioSyncOffset:)``
- ``getInputAudioMonitorType(inputName:)``
- ``setInputAudioMonitorType(inputName:monitorType:)``
- ``getInputAudioTracks(inputName:)``
- ``setInputAudioTracks(inputName:inputAudioTracks:)``
- ``getInputPropertiesListPropertyItems(inputName:propertyName:)``
- ``pressInputPropertiesButton(inputName:propertyName:)``
