import { ActivityIndicator } from "react-native";

export function Loading(){
    return(
        <ActivityIndicator style={{flex:1,justifyContent:"center",alignItems:"center"}}/>
    )
}