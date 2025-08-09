import FontAwesome from '@expo/vector-icons/FontAwesome';
import {  DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect, Suspense } from 'react';
import 'react-native-reanimated';
import { SQLiteProvider } from 'expo-sqlite';
import { Provider as PaperProvider } from 'react-native-paper';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { useColorScheme } from '@/components/useColorScheme';
import { databaseIni } from '@/database/databaseIni';
import { Loading } from '@/components/Loading';
import { DarkTheme, LightTheme} from '@/constants/Thema';
import { Platform } from 'react-native';


export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

export const unstable_settings = {
  // Ensure that reloading on `/modal` keeps a back button present.
  initialRouteName: '(tabs)',
};

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    SpaceMono: require('../../assets/fonts/SpaceMono-Regular.ttf'),
    ...FontAwesome.font,
  });

  // Expo Router uses Error Boundaries to catch errors in the navigation tree.
  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return(
    <Suspense fallback={<Loading />}>
      <PaperProvider>
        <GestureHandlerRootView> 
          {Platform.OS === 'web' ? (
            <RootLayoutNav />
          ) : (
            <SQLiteProvider databaseName='alarmes.db' onInit={databaseIni} useSuspense>
              <RootLayoutNav />
            </SQLiteProvider>
          )}
        </GestureHandlerRootView>
      </PaperProvider>
    </Suspense>
  )
}

function RootLayoutNav() {
  const colorScheme = useColorScheme();

  return (
    
      <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : LightTheme}>
        <Stack>
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          {/* <Stack.Screen name="modal" options={{ presentation: 'modal' }} /> */}
        </Stack>
      </ThemeProvider>
  );
}
