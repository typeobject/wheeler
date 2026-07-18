// Wheeler documentation-site policy; semantic docs are validated before this renderer runs.
// @ts-check
import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Wheeler',
  tagline: 'Reversible classical and quantum programming',
  favicon: 'img/wheeler-mark.svg',
  url: 'https://wheeler.typeobject.com',
  baseUrl: '/',
  organizationName: 'typeobject',
  projectName: 'wheeler',
  onBrokenLinks: 'throw',
  markdown: {hooks: {onBrokenMarkdownLinks: 'throw'}},
  i18n: {defaultLocale: 'en', locales: ['en']},
  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/typeobject/wheeler/tree/master/docs/',
        },
        blog: false,
        theme: {customCss: './src/css/custom.css'},
      },
    ],
  ],
  themeConfig: {
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    navbar: {
      title: 'Wheeler',
      logo: {
        alt: 'Wheeler quantum orbit',
        src: 'img/wheeler-mark.svg',
      },
      items: [
        {type: 'docSidebar', sidebarId: 'manual', position: 'left', label: 'Manual'},
        {to: '/reference/language-profile', label: 'Language', position: 'left'},
        {to: '/proposals/', label: 'WIPs', position: 'left'},
        {href: 'https://github.com/typeobject/wheeler', label: 'GitHub ↗', position: 'right'},
      ],
    },
    footer: {
      style: 'dark',
      copyright: `Wheeler / reversible by design / © ${new Date().getFullYear()} contributors`,
    },
    prism: {theme: prismThemes.github, darkTheme: prismThemes.dracula},
  },
};

export default config;
