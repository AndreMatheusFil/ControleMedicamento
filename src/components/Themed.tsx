import {
  Text as DefaultText,
  View as DefaultView,
  TextInput as DefaultTextInput,
  Switch as DefaultSwitch,
} from 'react-native';

import Colors from '@/constants/Colors';
import { useColorScheme } from './useColorScheme';
import { Checkbox as PaperCheckbox } from 'react-native-paper';

type ThemeProps = {
  lightColor?: string;
  darkColor?: string;
};

export type TextProps = ThemeProps & DefaultText['props'];
export type ViewProps = ThemeProps & DefaultView['props'];
export type TextInputProps = ThemeProps & DefaultTextInput['props'];
export type SwitchProps = ThemeProps & DefaultSwitch['props'];
export type CheckboxProps = {
  label: string;
  status: boolean;
  onPress: () => void;
};

export function useThemeColor(
  props: { light?: string; dark?: string },
  colorName: keyof typeof Colors.light & keyof typeof Colors.dark
) {
  const theme = useColorScheme() ?? 'light';
  const colorFromProps = props[theme];
  return colorFromProps ?? Colors[theme][colorName];
}

export function Text(props: TextProps) {
  const { style, lightColor, darkColor, ...otherProps } = props;
  const color = useThemeColor({ light: lightColor, dark: darkColor }, 'text');
  return <DefaultText style={[{ color }, style]} {...otherProps} />;
}

export function View(props: ViewProps) {
  const { style, lightColor, darkColor, ...otherProps } = props;
  const backgroundColor = useThemeColor({ light: lightColor, dark: darkColor }, 'background');
  return <DefaultView style={[{ backgroundColor }, style]} {...otherProps} />;
}

export function TextInput(props: TextInputProps) {
  const { style, lightColor, darkColor, ...otherProps } = props;
  const theme = useColorScheme() ?? 'light';
  const textColor = useThemeColor({ light: lightColor, dark: darkColor }, 'text');
  const backgroundColor = Colors[theme].card;
  const borderColor = Colors[theme].border;

  return (
    <DefaultTextInput
      placeholderTextColor={Colors[theme].text + '88'} // 88 = 53% opacity
      style={[
        {
          color: textColor,
          backgroundColor,
          borderColor,
          borderWidth: 1,
          borderRadius: 8,
          padding: 10,
        },
        style,
      ]}
      {...otherProps}
    />
  );
}

export function Checkbox({ label, status, onPress }: CheckboxProps) {
  const theme = useColorScheme() ?? 'light';

  return (
    <DefaultView style={{ flexDirection: 'row', alignItems: 'center', marginVertical: 4 }}>
      <PaperCheckbox
        status={status ? 'checked' : 'unchecked'}
        onPress={onPress}
        color={Colors[theme].tabIconSelected}
        uncheckedColor={Colors[theme].border}
      />
      <DefaultText style={{ fontSize: 16, color: Colors[theme].card }}>{label}</DefaultText>
    </DefaultView>
  );
}

export function Switch(props: SwitchProps) {
  const theme = useColorScheme() ?? 'light';
  const trackColor = {
    false: Colors[theme].border,
    true: Colors[theme].principal,
  };

  return (
    <DefaultSwitch
      trackColor={trackColor}
      thumbColor={props.value ? Colors[theme].text : '#f4f3f4'}
      ios_backgroundColor={Colors[theme].border}
      {...props}
    />
  );
}
