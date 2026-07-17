// @ts-check
import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Wheeler',
  tagline: 'Reversible classical and quantum programming',
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
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/typeobject/wheeler/tree/master/docs/',
        },
        blog: false,
        theme: {customCss: './src/css/custom.css'},
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'Wheeler',
      items: [
        {type: 'docSidebar', sidebarId: 'manual', position: 'left', label: 'Manual'},
        {to: '/docs/proposals/', label: 'WIPs', position: 'left'},
        {href: 'https://github.com/typeobject/wheeler', label: 'GitHub', position: 'right'},
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Wheeler',
          items: [
            {label: 'Language profile', to: '/docs/reference/language-profile'},
            {label: 'Improvement proposals', to: '/docs/proposals/'},
          ],
        },
        {
          title: 'Project',
          items: [{label: 'GitHub', href: 'https://github.com/typeobject/wheeler'}],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Wheeler contributors.`,
    },
    prism: {theme: prismThemes.github, darkTheme: prismThemes.dracula},
  },
};

export default config;
