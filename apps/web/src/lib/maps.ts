/**
 * Optional Maps JavaScript API browser key (restricted to Yummy Chops' domains in Google Cloud). Without it, maps are
 * drawn as schematic previews from the same API data. Address search never needs it: it goes through the API.
 */
export const GOOGLE_MAPS_BROWSER_KEY: string | undefined = process.env.NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY || undefined;
