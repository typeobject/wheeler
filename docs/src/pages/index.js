import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import styles from './index.module.css';

export default function Home() {
  return (
    <Layout title="Wheeler" description="Reversible classical and quantum programming">
      <main className={styles.hero}>
        <p className={styles.eyebrow}>REVERSIBLE · COHERENT · PORTABLE</p>
        <Heading as="h1">One language across classical and quantum systems</Heading>
        <p className={styles.summary}>
          Wheeler makes inverse execution, coherent computation, measurement, and replay
          explicit while keeping source familiar, readable, and teachable.
        </p>
        <div className={styles.actions}>
          <Link className="button button--primary button--lg" to="/docs/intro">
            Start with Wheeler
          </Link>
          <Link className="button button--secondary button--lg" to="/docs/proposals/">
            Read the WIPs
          </Link>
        </div>
      </main>
    </Layout>
  );
}
