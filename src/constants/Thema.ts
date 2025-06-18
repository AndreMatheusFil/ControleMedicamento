import Colors from "./Colors";
import { fonts } from "./Fonts";

export const DarkTheme = {
    dark: true,
    colors: {
      primary: Colors['dark'].principal,
      background: Colors['dark'].background,
      card: Colors['dark'].card,
      text: Colors['dark'].text,
      border: Colors['dark'].border,
      notification: Colors['dark'].notification,
    },
    fonts,
};

export const LightTheme = {
    dark: false,
    colors: {
        primary: Colors['dark'].principal,
        background: Colors['dark'].background,
        card: Colors['dark'].card,
        text: Colors['dark'].text,
        border: Colors['dark'].border,
        notification: Colors['dark'].notification,
    },
    fonts,
};
  