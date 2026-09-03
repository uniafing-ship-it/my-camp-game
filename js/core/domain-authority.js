// Stage 4: canonical V20 ownership boundary for migrated domains.
// Legacy may still drive the simulation, but consumers read domain state here.
export const V20_DOMAINS = Object.freeze([
  'resources', 'buildings', 'production', 'villagers',
  'combat', 'world', 'save', 'ui'
]);

const clone = value => {
  if (value == null) return value;
  if (typeof structuredClone === 'function') {
    try { return structuredClone(value); } catch (_) {}
  }
  return JSON.parse(JSON.stringify(value));
};

export function createDomainAuthority(state) {
  const revisions = new Map(V20_DOMAINS.map(name => [name, {
    revision: 0,
    source: 'uninitialized',
    updatedAt: 0
  }]));

  const assertDomain = name => {
    if (!revisions.has(name)) throw new Error(`Unknown V20 domain: ${name}`);
  };

  const commit = (name, value, options = {}) => {
    assertDomain(name);
    const nextValue = clone(value ?? {});
    state.set(name, nextValue);
    const previous = revisions.get(name);
    const nextMeta = Object.freeze({
      revision: previous.revision + 1,
      source: options.source || 'unknown',
      updatedAt: Number(options.at || Date.now())
    });
    revisions.set(name, nextMeta);
    state.set(`meta.authority.${name}`, nextMeta);
    return clone(nextValue);
  };

  const snapshot = name => {
    assertDomain(name);
    return clone(state.get(name) ?? {});
  };

  const status = () => Object.fromEntries(
    [...revisions.entries()].map(([name, meta]) => [name, {...meta}])
  );

  return Object.freeze({ domains: V20_DOMAINS, commit, snapshot, status });
}
