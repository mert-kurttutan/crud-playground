<script lang="ts">
	type BenchmarkRun = {
		id: number;
		name: string;
		script: string;
		hardware: string;
		score: number;
		unit: string;
		notes: string;
	};

	let nextId = 3;
	let apiStatus = $state('Not checked');
	let apiDetail = $state('Start FastAPI, then check the health endpoint.');
	let scoreError = $state('');

	let form = $state({
		name: '',
		script: '',
		hardware: '',
		score: '',
		unit: 'ops/sec',
		notes: ''
	});

	let runs = $state<BenchmarkRun[]>([
		{
			id: 1,
			name: 'Matrix multiply baseline',
			script: 'bench_matmul.py',
			hardware: 'Ryzen workstation',
			score: 1820,
			unit: 'ops/sec',
			notes: 'Initial CPU-only run'
		},
		{
			id: 2,
			name: 'Tokenizer throughput',
			script: 'bench_tokenizer.py',
			hardware: 'Laptop dev machine',
			score: 74,
			unit: 'MB/sec',
			notes: 'Warm cache'
		}
	]);

	function addBenchmark(event: SubmitEvent) {
		event.preventDefault();

		const rawScore = form.score.trim();
		const score = Number(rawScore);
		scoreError = '';

		if (rawScore === '' || Number.isNaN(score)) {
			scoreError = 'Score should be a number.';
			return;
		}

		if (!form.name.trim() || !form.script.trim() || !form.hardware.trim()) {
			return;
		}

		runs.unshift({
			id: nextId,
			name: form.name.trim(),
			script: form.script.trim(),
			hardware: form.hardware.trim(),
			score,
			unit: form.unit.trim() || 'score',
			notes: form.notes.trim()
		});

		nextId += 1;
		form.name = '';
		form.script = '';
		form.hardware = '';
		form.score = '';
		form.unit = 'ops/sec';
		form.notes = '';
		scoreError = '';
	}

	function clearScoreError() {
		if (scoreError) {
			scoreError = '';
		}
	}

	function removeBenchmark(id: number) {
		const index = runs.findIndex((run) => run.id === id);

		if (index !== -1) {
			runs.splice(index, 1);
		}
	}

	const healthUrl = '/api/v1/health';

	async function checkApi() {
		apiStatus = 'Checking';
		apiDetail = `Async call to ${healthUrl}`;

		const controller = new AbortController();
		const timeout = window.setTimeout(() => controller.abort(), 2000);

		try {
			const response = await fetch(healthUrl, {
				signal: controller.signal
			});
			const data = await response.json();
			apiStatus = response.ok ? 'Online' : 'Error';
			apiDetail = `API: ${data.status ?? 'unknown'}, database: ${data.database ?? 'unknown'}`;
		} catch (error) {
			apiStatus = 'Offline';
			apiDetail = error instanceof Error ? error.message : 'Could not reach FastAPI';
		} finally {
			window.clearTimeout(timeout);
		}
	}
</script>

<svelte:head>
	<title>Benchmark CRUD Playground</title>
	<meta
		name="description"
		content="A minimal SvelteKit UI for adding benchmark runs while exploring CRUD patterns."
	/>
</svelte:head>

<main class="shell">
	<header class="topbar">
		<div>
			<p class="eyebrow">CRUD playground</p>
			<h1>Benchmark runs</h1>
		</div>
		<button type="button" class="secondary" onclick={checkApi}>Check API</button>
	</header>

	<section class="status" aria-label="API status">
		<div>
			<span>FastAPI</span>
			<strong>{apiStatus}</strong>
		</div>
		<p>{apiDetail}</p>
	</section>

	<section class="workspace">
		<form class="panel" onsubmit={addBenchmark}>
			<div>
				<p class="eyebrow">Create</p>
				<h2>Add benchmark</h2>
			</div>

			<label>
				Name
				<input bind:value={form.name} placeholder="Matrix multiply baseline" required />
			</label>

			<label>
				Script
				<input bind:value={form.script} placeholder="bench_matmul.py" required />
			</label>

			<label>
				Hardware
				<input bind:value={form.hardware} placeholder="Ryzen workstation" required />
			</label>

			<div class="field-row">
				<label>
					Score
					<input
						bind:value={form.score}
						aria-describedby={scoreError ? 'score-error' : undefined}
						aria-invalid={scoreError ? 'true' : undefined}
						inputmode="decimal"
						oninput={clearScoreError}
						placeholder="1820"
						required
					/>
					{#if scoreError}
						<span id="score-error" class="error">{scoreError}</span>
					{/if}
				</label>

				<label>
					Unit
					<input bind:value={form.unit} placeholder="ops/sec" />
				</label>
			</div>

			<label>
				Notes
				<textarea bind:value={form.notes} rows="4" placeholder="Initial CPU-only run"></textarea>
			</label>

			<button type="submit">Add run</button>
		</form>

		<section class="panel list-panel" aria-label="Benchmark run list">
			<div class="list-header">
				<div>
					<p class="eyebrow">Read</p>
					<h2>Recent runs</h2>
				</div>
				<span>{runs.length} total</span>
			</div>

			<div class="run-list">
				{#each runs as run}
					<article class="run">
						<div>
							<h3>{run.name}</h3>
							<p>{run.script} on {run.hardware}</p>
						</div>

						<div class="metric">
							<strong>{run.score}</strong>
							<span>{run.unit}</span>
						</div>

						<p class="notes">{run.notes || 'No notes'}</p>

						<button
							type="button"
							class="remove"
							aria-label={`Remove ${run.name}`}
							onclick={() => removeBenchmark(run.id)}
						>
							Remove
						</button>
					</article>
				{/each}
			</div>
		</section>
	</section>
</main>

<style>
	:global(*) {
		box-sizing: border-box;
	}

	:global(body) {
		margin: 0;
		min-width: 320px;
		background: #f5f7f8;
		color: #172126;
		font-family:
			Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
	}

	button,
	input,
	textarea {
		font: inherit;
	}

	.shell {
		width: min(1120px, calc(100% - 32px));
		margin: 0 auto;
		padding: 32px 0;
	}

	.topbar {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 16px;
		align-items: center;
		margin-bottom: 20px;
	}

	.eyebrow {
		margin: 0 0 6px;
		color: #5b6870;
		font-size: 0.78rem;
		font-weight: 700;
		letter-spacing: 0;
		text-transform: uppercase;
	}

	h1,
	h2,
	h3,
	p {
		margin-top: 0;
	}

	h1 {
		margin-bottom: 0;
		font-size: clamp(2.4rem, 8vw, 4.75rem);
		line-height: 0.95;
	}

	h2 {
		margin-bottom: 0;
		font-size: 1.25rem;
	}

	h3 {
		margin-bottom: 6px;
		font-size: 1rem;
	}

	.status,
	.panel {
		border: 1px solid #dce3e6;
		border-radius: 8px;
		background: #ffffff;
	}

	.status {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 20px;
		align-items: center;
		margin-bottom: 20px;
		padding: 16px;
	}

	.status span {
		display: block;
		margin-bottom: 4px;
		color: #5b6870;
		font-size: 0.78rem;
		font-weight: 700;
		text-transform: uppercase;
	}

	.status strong {
		display: block;
		font-size: 1.1rem;
	}

	.status p {
		margin-bottom: 0;
		color: #526069;
	}

	.workspace {
		display: grid;
		grid-template-columns: minmax(280px, 380px) 1fr;
		gap: 16px;
		align-items: start;
	}

	.panel {
		padding: 20px;
	}

	form {
		display: grid;
		gap: 14px;
	}

	label {
		display: grid;
		gap: 7px;
		color: #344149;
		font-size: 0.9rem;
		font-weight: 700;
	}

	input,
	textarea {
		width: 100%;
		border: 1px solid #cbd5da;
		border-radius: 6px;
		background: #ffffff;
		color: #172126;
		padding: 10px 12px;
		font-weight: 500;
	}

	textarea {
		resize: vertical;
	}

	input:focus,
	textarea:focus {
		border-color: #147d7e;
		outline: 3px solid rgb(20 125 126 / 16%);
	}

	input[aria-invalid='true'] {
		border-color: #b42318;
	}

	input[aria-invalid='true']:focus {
		outline-color: rgb(180 35 24 / 16%);
	}

	.error {
		color: #b42318;
		font-size: 0.82rem;
		font-weight: 700;
	}

	button {
		border: 0;
		border-radius: 6px;
		background: #147d7e;
		color: #ffffff;
		cursor: pointer;
		font-weight: 800;
		padding: 10px 14px;
	}

	button:hover {
		background: #0d696b;
	}

	.secondary {
		background: #26343b;
	}

	.secondary:hover {
		background: #172126;
	}

	.field-row,
	.list-header,
	.run {
		display: grid;
		gap: 16px;
	}

	.field-row {
		grid-template-columns: 1fr 1fr;
	}

	.list-panel {
		min-width: 0;
	}

	.list-header {
		grid-template-columns: 1fr auto;
		align-items: center;
		margin-bottom: 16px;
	}

	.list-header span {
		color: #526069;
		font-weight: 700;
	}

	.run-list {
		display: grid;
		gap: 12px;
	}

	.run {
		grid-template-columns: 1fr auto;
		gap: 10px 16px;
		border: 1px solid #e1e7ea;
		border-radius: 8px;
		padding: 14px;
	}

	.run p,
	.notes {
		margin-bottom: 0;
		color: #526069;
	}

	.metric {
		min-width: 96px;
		text-align: right;
	}

	.metric strong,
	.metric span {
		display: block;
	}

	.metric strong {
		font-size: 1.4rem;
	}

	.metric span {
		color: #526069;
		font-size: 0.82rem;
		font-weight: 700;
	}

	.notes,
	.remove {
		grid-column: 1 / -1;
	}

	.remove {
		justify-self: end;
		background: #eef2f3;
		color: #26343b;
		padding: 8px 10px;
	}

	.remove:hover {
		background: #dde5e8;
	}

	@media (max-width: 760px) {
		.shell {
			width: min(100% - 24px, 1120px);
			padding: 20px 0;
		}

		.topbar,
		.status,
		.workspace,
		.field-row,
		.run {
			grid-template-columns: 1fr;
		}

		.secondary {
			width: 100%;
		}

		.metric {
			text-align: left;
		}
	}
</style>
